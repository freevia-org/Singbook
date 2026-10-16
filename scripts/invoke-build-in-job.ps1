param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter()]
    [string[]]$ArgumentList = @(),
    [Parameter()]
    [string]$WorkingDirectory = (Get-Location).Path,
    # Test-only gates used to prove job membership precedes the first resume.
    [Parameter()]
    [string]$TestCreatedEventName,
    [Parameter()]
    [string]$TestResumeEventName,
    [Parameter()]
    [string]$TestCreatedProcessIdPath,
    [Parameter()]
    [switch]$TestFailBeforeResume
)

$ErrorActionPreference = 'Stop'

if (-not ('SingbookBuildJob' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Diagnostics;
using System.IO;

public static class SingbookBuildJob
{
    private const uint CreateSuspended = 0x00000004;
    private const uint CreateNoWindow = 0x08000000;
    private const uint ExtendedStartupInfoPresent = 0x00080000;
    private const uint StartfUseStdHandles = 0x00000100;
    private const uint JobObjectExtendedLimitInformation = 9;
    private const uint JobObjectLimitKillOnJobClose = 0x00002000;
    private const uint HandleFlagInherit = 0x00000001;
    private const uint WaitObject0 = 0x00000000;
    private const uint Infinite = 0xFFFFFFFF;
    private const uint ProcThreadAttributeJobList = 0x0002000D;
    private const int JobObjectBasicAccountingInformation = 1;
    private const int CleanupTimeoutMilliseconds = 5000;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct StartupInfo
    {
        public uint cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public uint dwX;
        public uint dwY;
        public uint dwXSize;
        public uint dwYSize;
        public uint dwXCountChars;
        public uint dwYCountChars;
        public uint dwFillAttribute;
        public uint dwFlags;
        public ushort wShowWindow;
        public ushort cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ProcessInformation
    {
        public IntPtr hProcess;
        public IntPtr hThread;
        public uint dwProcessId;
        public uint dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct StartupInfoEx
    {
        public StartupInfo StartupInfo;
        public IntPtr AttributeList;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BasicAccountingInformation
    {
        public long TotalUserTime;
        public long TotalKernelTime;
        public long ThisPeriodTotalUserTime;
        public long ThisPeriodTotalKernelTime;
        public uint TotalPageFaultCount;
        public uint TotalProcesses;
        public uint ActiveProcesses;
        public uint TotalTerminatedProcesses;
    }

    private sealed class JobState
    {
        public IntPtr Handle;
        public readonly object Sync = new object();
        public int RetirementError;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BasicLimitInformation
    {
        public long PerProcessUserTimeLimit;
        public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass;
        public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct IoCounters
    {
        public ulong ReadOperationCount;
        public ulong WriteOperationCount;
        public ulong OtherOperationCount;
        public ulong ReadTransferCount;
        public ulong WriteTransferCount;
        public ulong OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ExtendedLimitInformation
    {
        public BasicLimitInformation BasicLimitInformation;
        public IoCounters IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CreateJobObject(IntPtr attributes, string name);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetInformationJobObject(IntPtr job, uint infoClass,
        ref ExtendedLimitInformation info, uint infoLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetHandleInformation(IntPtr handle, uint mask, uint flags);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool InitializeProcThreadAttributeList(IntPtr attributeList,
        int attributeCount, uint flags, ref IntPtr size);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool UpdateProcThreadAttribute(IntPtr attributeList, uint flags,
        IntPtr attribute, IntPtr value, IntPtr size, IntPtr previousValue, IntPtr returnSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern void DeleteProcThreadAttributeList(IntPtr attributeList);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int standardHandle);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CreateProcess(string applicationName, StringBuilder commandLine,
        IntPtr processAttributes, IntPtr threadAttributes, bool inheritHandles,
        uint creationFlags, IntPtr environment, string currentDirectory,
        ref StartupInfoEx startupInfo, out ProcessInformation processInformation);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint ResumeThread(IntPtr thread);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool TerminateJobObject(IntPtr job, uint exitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetExitCodeProcess(IntPtr process, out uint exitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool QueryInformationJobObject(IntPtr job, int infoClass,
        out BasicAccountingInformation info, uint infoLength, IntPtr returnLength);

    public static int Run(string filePath, string[] arguments, string workingDirectory,
        string testCreatedEventName, string testResumeEventName, string testCreatedProcessIdPath,
        bool testFailBeforeResume)
    {
        JobState job = new JobState();
        ProcessInformation process = new ProcessInformation();
        bool processCreated = false;
        IntPtr attributeList = IntPtr.Zero;
        IntPtr jobHandleArray = IntPtr.Zero;
        ConsoleCancelEventHandler cancelHandler = null;
        EventWaitHandle testCreatedEvent = null;
        EventWaitHandle testResumeEvent = null;
        int exitCode = 1;
        try
        {
            job.Handle = CreateJobObject(IntPtr.Zero, null);
            Check(job.Handle != IntPtr.Zero, "CreateJobObject");
            Check(SetHandleInformation(job.Handle, HandleFlagInherit, 0), "SetHandleInformation(job)");

            ExtendedLimitInformation limits = new ExtendedLimitInformation();
            limits.BasicLimitInformation.LimitFlags = JobObjectLimitKillOnJobClose;
            Check(SetInformationJobObject(job.Handle, JobObjectExtendedLimitInformation,
                ref limits, (uint)Marshal.SizeOf(typeof(ExtendedLimitInformation))),
                "SetInformationJobObject");

            if (!String.IsNullOrEmpty(testCreatedEventName))
                testCreatedEvent = EventWaitHandle.OpenExisting(testCreatedEventName);
            if (!String.IsNullOrEmpty(testResumeEventName))
                testResumeEvent = EventWaitHandle.OpenExisting(testResumeEventName);

            IntPtr attributeListSize = IntPtr.Zero;
            InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref attributeListSize);
            Check(attributeListSize != IntPtr.Zero, "InitializeProcThreadAttributeList(size)");
            attributeList = Marshal.AllocHGlobal(attributeListSize);
            Check(InitializeProcThreadAttributeList(attributeList, 1, 0, ref attributeListSize),
                "InitializeProcThreadAttributeList");
            jobHandleArray = Marshal.AllocHGlobal(IntPtr.Size);
            Marshal.WriteIntPtr(jobHandleArray, job.Handle);
            Check(UpdateProcThreadAttribute(attributeList, 0,
                new IntPtr(ProcThreadAttributeJobList), jobHandleArray,
                new IntPtr(IntPtr.Size), IntPtr.Zero, IntPtr.Zero),
                "UpdateProcThreadAttribute(job list)");

            StartupInfoEx startup = new StartupInfoEx();
            startup.StartupInfo.cb = (uint)Marshal.SizeOf(typeof(StartupInfoEx));
            startup.AttributeList = attributeList;
            startup.StartupInfo.hStdInput = GetStdHandle(-10);
            startup.StartupInfo.hStdOutput = GetStdHandle(-11);
            startup.StartupInfo.hStdError = GetStdHandle(-12);
            IntPtr invalidHandle = new IntPtr(-1);
            bool inheritStandardHandles = startup.StartupInfo.hStdInput != IntPtr.Zero && startup.StartupInfo.hStdInput != invalidHandle &&
                startup.StartupInfo.hStdOutput != IntPtr.Zero && startup.StartupInfo.hStdOutput != invalidHandle &&
                startup.StartupInfo.hStdError != IntPtr.Zero && startup.StartupInfo.hStdError != invalidHandle;
            if (inheritStandardHandles)
                startup.StartupInfo.dwFlags = StartfUseStdHandles;
            else
                startup.StartupInfo.dwFlags = 0;

            StringBuilder commandLine = new StringBuilder(Quote(filePath));
            foreach (string argument in arguments)
            {
                commandLine.Append(' ');
                commandLine.Append(Quote(argument));
            }

            Check(CreateProcess(filePath, commandLine, IntPtr.Zero, IntPtr.Zero,
                inheritStandardHandles, CreateSuspended | ExtendedStartupInfoPresent | CreateNoWindow, IntPtr.Zero, workingDirectory,
                ref startup, out process), "CreateProcess");
            processCreated = true;

            cancelHandler = delegate(object sender, ConsoleCancelEventArgs eventArgs)
            {
                eventArgs.Cancel = true;
                lock (job.Sync)
                {
                    if (job.Handle != IntPtr.Zero && !TerminateJobObject(job.Handle, 130))
                    {
                        job.RetirementError = Marshal.GetLastWin32Error();
                        CloseJobLocked(job);
                    }
                }
            };
            Console.CancelKeyPress += cancelHandler;

            if (!String.IsNullOrEmpty(testCreatedProcessIdPath))
                File.WriteAllText(testCreatedProcessIdPath, process.dwProcessId.ToString());
            if (testCreatedEvent != null)
                testCreatedEvent.Set();
            if (testResumeEvent != null)
                testResumeEvent.WaitOne();
            if (testFailBeforeResume)
                throw new InvalidOperationException("Test failure before resuming the suspended worker.");

            if (ResumeThread(process.hThread) == 0xFFFFFFFF)
            {
                int error = Marshal.GetLastWin32Error();
                throw new Win32Exception(error, "ResumeThread failed");
            }

            uint waitResult = WaitForSingleObject(process.hProcess, Infinite);
            Check(waitResult == WaitObject0, "WaitForSingleObject");
            uint processExitCode;
            Check(GetExitCodeProcess(process.hProcess, out processExitCode), "GetExitCodeProcess");
            exitCode = unchecked((int)processExitCode);
            return exitCode;
        }
        finally
        {
            if (cancelHandler != null)
                Console.CancelKeyPress -= cancelHandler;
            Exception cleanupFailure = null;
            try
            {
                RequestJobTermination(job, unchecked((uint)exitCode));
            }
            catch (Exception exception)
            {
                cleanupFailure = exception;
            }
            try
            {
                if (processCreated)
                {
                    IntPtr threadHandle = process.hThread;
                    process.hThread = IntPtr.Zero;
                    if (!CloseHandle(threadHandle) && cleanupFailure == null)
                        cleanupFailure = new Win32Exception(Marshal.GetLastWin32Error(), "CloseHandle(thread) failed");
                    IntPtr processHandle = process.hProcess;
                    process.hProcess = IntPtr.Zero;
                    if (!CloseHandle(processHandle) && cleanupFailure == null)
                        cleanupFailure = new Win32Exception(Marshal.GetLastWin32Error(), "CloseHandle(process) failed");
                }
            }
            finally
            {
                try
                {
                    WaitAndRetireJob(job, CleanupTimeoutMilliseconds);
                }
                catch (Exception exception) { if (cleanupFailure == null) cleanupFailure = exception; }

                if (attributeList != IntPtr.Zero)
                {
                    DeleteProcThreadAttributeList(attributeList);
                    Marshal.FreeHGlobal(attributeList);
                }
                if (jobHandleArray != IntPtr.Zero)
                    Marshal.FreeHGlobal(jobHandleArray);
                if (testCreatedEvent != null) testCreatedEvent.Dispose();
                if (testResumeEvent != null) testResumeEvent.Dispose();
            }
            if (cleanupFailure != null) throw cleanupFailure;
        }
    }

    private static void RequestJobTermination(JobState job, uint exitCode)
    {
        lock (job.Sync)
        {
            if (job.Handle == IntPtr.Zero)
            {
                if (job.RetirementError != 0)
                    throw new Win32Exception(job.RetirementError, "Cancel-time job termination failed");
                return;
            }
            if (!TerminateJobObject(job.Handle, exitCode))
            {
                int error = Marshal.GetLastWin32Error();
                job.RetirementError = error;
                CloseJobLocked(job);
                throw new Win32Exception(error, "TerminateJobObject failed");
            }
        }
    }

    private static void WaitAndRetireJob(JobState job, int timeoutMilliseconds)
    {
        IntPtr handle;
        lock (job.Sync)
        {
            handle = job.Handle;
            if (handle == IntPtr.Zero)
            {
                if (job.RetirementError != 0)
                    throw new Win32Exception(job.RetirementError, "Build job handle retirement failed");
                return;
            }
        }
        try
        {
            Stopwatch timer = Stopwatch.StartNew();
            while (timer.ElapsedMilliseconds < timeoutMilliseconds)
            {
                BasicAccountingInformation accounting;
                Check(QueryInformationJobObject(handle, JobObjectBasicAccountingInformation,
                    out accounting, (uint)Marshal.SizeOf(typeof(BasicAccountingInformation)), IntPtr.Zero),
                    "QueryInformationJobObject");
                if (accounting.ActiveProcesses == 0)
                {
                    lock (job.Sync)
                    {
                        CloseJobLocked(job);
                        if (job.RetirementError != 0)
                            throw new Win32Exception(job.RetirementError, "Closing the build job failed");
                    }
                    return;
                }
                Thread.Sleep(20);
            }
            throw new TimeoutException("Owned build processes did not exit within the cleanup timeout.");
        }
        catch
        {
            lock (job.Sync)
                CloseJobLocked(job);
            throw;
        }
    }

    private static void CloseJobLocked(JobState job)
    {
        if (job.Handle == IntPtr.Zero)
            return;
        IntPtr handle = job.Handle;
        job.Handle = IntPtr.Zero;
        if (!CloseHandle(handle) && job.RetirementError == 0)
            job.RetirementError = Marshal.GetLastWin32Error();
    }

    private static string Quote(string value)
    {
        if (value.Length > 0 && value.IndexOfAny(new char[] { ' ', '\t', '\n', '\v', '"' }) < 0)
            return value;

        StringBuilder result = new StringBuilder();
        result.Append('"');
        int slashes = 0;
        for (int i = 0; i < value.Length; i++)
        {
            char current = value[i];
            if (current == '\\')
            {
                slashes++;
                continue;
            }
            if (current == '"')
            {
                result.Append('\\', slashes * 2 + 1);
                result.Append('"');
                slashes = 0;
                continue;
            }
            result.Append('\\', slashes);
            result.Append(current);
            slashes = 0;
        }
        result.Append('\\', slashes * 2);
        result.Append('"');
        return result.ToString();
    }

    private static void Check(bool success, string operation)
    {
        if (!success)
            throw new Win32Exception(Marshal.GetLastWin32Error(), operation + " failed");
    }
}
'@
}

$exitCode = [SingbookBuildJob]::Run($FilePath, $ArgumentList, $WorkingDirectory,
    $TestCreatedEventName, $TestResumeEventName, $TestCreatedProcessIdPath,
    [bool]$TestFailBeforeResume)
$exitCode
