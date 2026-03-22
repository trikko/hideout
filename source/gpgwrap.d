module gpgwrap;

import std;
import core.atomic;


/**
 * Progress information for a GPG operation.
 */
struct GPGProgress {
    size_t bytesWritten;
    size_t bytesRead;
    size_t totalInput;

    /**
     * Returns the progress percentage based on input written (0.0 to 100.0).
     * Returns 0.0 if totalInput is 0.
     */
    double percent() const {
        if (totalInput == 0) return 0.0;
        return (cast(double)bytesWritten / totalInput) * 100.0;
    }
}

/**
 * Exception thrown when GPG execution fails.
 */
class GPGException : Exception {
    int returnCode;
    string stdout;
    string stderr;

    this(int rc, string so, string se, string file = __FILE__, size_t line = __LINE__) {
        this.returnCode = rc;
        this.stdout = so;
        this.stderr = se;
        super("GPG exited with code " ~ rc.to!string ~ "\n\nSTDERR:\n" ~ se ~ "\n\nSTDOUT:\n" ~ so, file, line);
    }
}

/**
 * Result of a GPG operation.
 */
class GPGResult {
    int returnCode;
    ubyte[] bytes;

    /**
     * Returns the result as a string.
     */
    string chars() { return cast(string) bytes; }
}

/**
 * GPG wrapper class.
 */
class GPG {
    private {
        string _executable = "gpg";
        string _recipient;
        ubyte[] _input;
        string _inputFrom;
        bool _armored;
        string _outputTo;
        bool _outputToStdout;
        char[] _passphrase;
        shared bool _cancelled = false;
        
        enum OP { unknown, encrypt, decrypt }
        OP _operation = OP.unknown;
    }

    /**
     * Constructor.
     * @param exe Path to the gpg executable.
     */
    this(string exe = "gpg") {
        _executable = exe;
    }

    /// Set the recipient for encryption.
    GPG recipient(string r) { _recipient = r; return this; }
    
    /// Set operation to encrypt.
    GPG encrypt() { _operation = OP.encrypt; return this; }
    
    /// Set operation to decrypt.
    GPG decrypt() { _operation = OP.decrypt; return this; }
    
    /// Set input data from a string.
    GPG input(string s) { _input = cast(ubyte[])s.dup; return this; }
    
    /// Set input data from a byte array.
    GPG input(ubyte[] b) { _input = b.dup; return this; }
    
    /// Set input from a file path.
    GPG inputFrom(string file) { _inputFrom = file; return this; }
    
    /// Enable/disable armored output.
    GPG armor(bool a = true) { _armored = a; return this; }
    
    /// Set passphrase for symmetric encryption or decryption.
    GPG passphrase(const(char)[] p) { 
        _passphrase = p.dup; 
        return this; 
    }
    
    /// Set output file path.
    GPG outputTo(string file) { _outputTo = file; return this; }
    
    /// Force output to stdout.
    GPG outputToStdout(bool s = true) { _outputToStdout = s; return this; }

    /// Cancel an ongoing wait() operation.
    void cancel() {
        atomicStore(_cancelled, true);
    }
    
    /**
     * Executes GPG with --help and returns the version string.
     * Returns an empty string if GPG is not found or fails.
     */
    string getVersion() {
        try {
            auto res = execute([_executable, "--help"]);
            if (res.status != 0) return "";
            
            // The version is usually in the first line: "gpg (GnuPG) X.Y.Z"
            auto lines = res.output.splitLines();
            if (lines.length == 0) return "";
            
            auto parts = lines[0].split();
            if (parts.length > 0) {
                return parts[$-1]; // Usually the last part of the first line
            }
        } catch (Exception) {
            // GPG not found or other process error
        }
        return "";
    }

    /**
     * Executes the GPG command and waits for completion.
     * @param onProgress Optional callback for progress monitoring.
     * @return GPGResult containing the output.
     * @throws GPGException if the command fails.
     */
    GPGResult wait(void delegate(GPGProgress) onProgress = null) {
        auto params = ["--batch", "--yes", "--status-fd", "2"];
        
        if (_passphrase.length) params ~= ["--passphrase-fd", "0"];
        else if (_recipient.length) params ~= ["-r", _recipient];

        string actualOutput = _outputTo;
        string tempOutput;

        if (_outputTo.length) {
            import std.uuid : randomUUID;
            import std.file : tempDir;
            import std.path : buildPath;
            import std.string : indexOf;
            
            bool isPortal = (_outputTo.indexOf("/run/user/") >= 0 && _outputTo.indexOf("/doc/") >= 0);
            
            if (isPortal) {
                // For portal paths, we must use a location that is definitely writable (like /tmp)
                tempOutput = buildPath(tempDir(), "hideout-gpg-" ~ randomUUID().toString() ~ ".partial");
            } else {
                // For regular paths, a sibling temp file ensures we stay on the same filesystem
                // so rename() is atomic and doesn't require a data copy.
                tempOutput = _outputTo ~ ".partial." ~ randomUUID().toString();
            }
            params ~= ["-o", tempOutput];
        } else if (_outputToStdout) {
            params ~= ["-o", "-"];
        }

        if (_armored) params ~= "-a";

        if (_operation == OP.encrypt) {
            if (_passphrase.length) params ~= "-c";
            else if (_recipient.length) params ~= "-e";
        } else if (_operation == OP.decrypt) {
            params ~= "-d";
        }

        if (_inputFrom.length && _input.length == 0) {
            // We will stream the file ourselves to track progress
        } else if (_inputFrom.length) {
            params ~= _inputFrom;
        }

        auto pipes = pipeProcess([_executable] ~ params, Redirect.all);
        
        if (_passphrase.length) {
            pipes.stdin.rawWrite(cast(ubyte[]) _passphrase);
            pipes.stdin.rawWrite(cast(ubyte[]) "\n");
            pipes.stdin.flush();
            
            foreach (ref c; _passphrase) {
                c = cast(char)uniform(1, 255);
            }
            _passphrase = null;
        }
        
        shared size_t sharedBytesWritten = 0;
        shared size_t sharedBytesRead = 0;
        size_t totalInputSize = _input.length;

        if (_inputFrom.length && _input.length == 0) {
            import std.file : getSize;
            try {
                totalInputSize = cast(size_t)getSize(_inputFrom);
            } catch (Exception) {
                totalInputSize = 0;
            }
        }

        // Use a simple class to capture data across threads without slice issues
        static class OutputBuffer { ubyte[] data; }
        auto outBuf = new OutputBuffer();
        auto errBuf = new OutputBuffer();
        
        import std.parallelism;

        auto taskStdin = task((ubyte[] input, string filename, File f, shared(size_t)* written, shared(size_t)* read, void delegate(GPGProgress) cb, size_t total, shared(bool)* cancelled) {
            import std.stdio : File;
            if (filename.length > 0 && input.length == 0) {
                auto inFile = File(filename, "rb");
                ubyte[8192] buffer;
                size_t pos = 0;
                while (!atomicLoad(*cancelled)) {
                    auto readSlice = inFile.rawRead(buffer);
                    if (readSlice.length == 0) break;
                    try {
                        f.rawWrite(readSlice);
                        f.flush();
                    } catch (Exception) { break; }
                    pos += readSlice.length;
                    atomicStore(*written, pos);
                    if (cb) cb(GPGProgress(atomicLoad(*written), atomicLoad(*read), total));
                }
                inFile.close();
            } else if (input.length > 0) {
                size_t pos = 0;
                while (pos < input.length && !atomicLoad(*cancelled)) {
                    size_t toWrite = min(4096, input.length - pos);
                    try {
                        f.rawWrite(input[pos .. pos + toWrite]);
                        f.flush();
                    } catch (Exception) { break; }
                    pos += toWrite;
                    atomicStore(*written, pos);
                    if (cb) cb(GPGProgress(atomicLoad(*written), atomicLoad(*read), total));
                }
            }
            try { f.close(); } catch(Exception){}
        }, _input, _inputFrom.length && _input.length == 0 ? _inputFrom : "", pipes.stdin, &sharedBytesWritten, &sharedBytesRead, onProgress, totalInputSize, &_cancelled);

        auto taskStdout = task((OutputBuffer buf, File f, shared(size_t)* written, shared(size_t)* read, void delegate(GPGProgress) cb, size_t total, shared(bool)* cancelled) {
            ubyte[4096] buffer;
            while (true) {
                if (atomicLoad(*cancelled)) break;
                ubyte[] readSlice;
                try {
                    readSlice = f.rawRead(buffer);
                } catch (Exception) { break; }
                if (readSlice.length == 0) break;
                buf.data ~= readSlice;
                atomicOp!"+="( *read, readSlice.length);
                if (cb) cb(GPGProgress(atomicLoad(*written), atomicLoad(*read), total));
            }
        }, outBuf, pipes.stdout, &sharedBytesWritten, &sharedBytesRead, onProgress, totalInputSize, &_cancelled);

        shared bool _failedEarly = false;
        shared bool _processTerminated = false;

        auto taskStderr = task((OutputBuffer buf, File f, shared(bool)* cancelled, shared(bool)* failedEarly) {
            try {
                foreach (line; f.byLine()) {
                    if (atomicLoad(*cancelled)) break;
                    
                    buf.data ~= cast(ubyte[])(line ~ "\n");
                    
                    import std.string : indexOf;
                    string currentErr = cast(string)line;
                    if (currentErr.indexOf("[GNUPG:] DECRYPTION_FAILED") >= 0 || currentErr.indexOf("[GNUPG:] BAD_PASSPHRASE") >= 0) {
                        atomicStore(*failedEarly, true);
                        break;
                    }
                }
            } catch(Exception) {}
        }, errBuf, pipes.stderr, &_cancelled, &_failedEarly);

        taskStdin.executeInNewThread();
        taskStdout.executeInNewThread();
        taskStderr.executeInNewThread();

        import core.thread;
        while (!taskStdin.done || !taskStdout.done || !taskStderr.done) {
            if (atomicLoad(_cancelled) || atomicLoad(_failedEarly)) {
                // Kill the process se annullato o se gpg ha già notificato l'errore palese
                try { pipes.pid.kill(); } catch (Exception) {}
                break;
            }
            Thread.sleep(10.msecs);
        }

        taskStdin.yieldForce();
        taskStdout.yieldForce();
        taskStderr.yieldForce();

        int status = std.process.wait(pipes.pid);

        if (atomicLoad(_failedEarly)) {
            if (tempOutput.length && exists(tempOutput)) try { remove(tempOutput); } catch (Exception) {}
            // Forza il codice errore a 2 siccome terminato prematuramente per password
            throw new GPGException(2, cast(string)outBuf.data, cast(string)errBuf.data);
        }

        if (atomicLoad(_cancelled)) {
            if (tempOutput.length && exists(tempOutput)) try { remove(tempOutput); } catch (Exception) {}
            throw new GPGException(-1, "Operation cancelled by user", cast(string)outBuf.data ~ cast(string)errBuf.data);
        }

        if (status != 0) {
            if (tempOutput.length && exists(tempOutput)) try { remove(tempOutput); } catch (Exception) {}
            throw new GPGException(status, cast(string)outBuf.data, cast(string)errBuf.data);
        }

        if (tempOutput.length && exists(tempOutput)) {
            try {
                if (exists(actualOutput)) remove(actualOutput);
                try {
                    rename(tempOutput, actualOutput);
                } catch (Exception) {
                    // Fallback for cross-filesystem move (EXDEV)
                    copy(tempOutput, actualOutput);
                    remove(tempOutput);
                }
            } catch (Exception e) {
                throw new GPGException(status, "Failed to move temp file: " ~ e.msg, cast(string)outBuf.data);
            }
        }

        auto res = new GPGResult();
        res.returnCode = status;
        res.bytes = outBuf.data;
        return res;
    }
}

/**
 * Helper function to create a new GPG instance.
 */
GPG gpg(string exe = "gpg") {
    return new GPG(exe);
}
