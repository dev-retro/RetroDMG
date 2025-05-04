print("Testing RetroDMG CLI")

#if os(macOS)
    print("Running on macOS")
#elseif os(Linux)
    print("Running on Linux")
#elseif os(Windows)
    print("Running on Windows")
#else
    print("Running on an unsupported OS")
#endif
