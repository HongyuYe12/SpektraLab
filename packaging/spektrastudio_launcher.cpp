#define UNICODE
#define _UNICODE

#include <windows.h>

#include <filesystem>
#include <string>
#include <vector>

namespace {

std::wstring quote(const std::wstring& value) {
    return L"\"" + value + L"\"";
}

std::wstring executable_directory() {
    std::vector<wchar_t> buffer(32768);
    const DWORD length = GetModuleFileNameW(nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0 || length >= buffer.size()) {
        return {};
    }
    return std::filesystem::path(std::wstring(buffer.data(), length)).parent_path().wstring();
}

void show_error(const std::wstring& message) {
    MessageBoxW(nullptr, message.c_str(), L"SpektraStudio", MB_OK | MB_ICONERROR);
}

}  // namespace

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    const std::wstring app_dir = executable_directory();
    if (app_dir.empty()) {
        show_error(L"Unable to locate the SpektraStudio installation directory.");
        return 1;
    }

    const std::filesystem::path runtime_dir = std::filesystem::path(app_dir) / L"runtime";
    const std::filesystem::path pythonw = runtime_dir / L"pythonw.exe";
    const std::filesystem::path qt_dir = runtime_dir / L"Lib" / L"site-packages" / L"PySide6";
    if (!std::filesystem::exists(pythonw)) {
        show_error(L"The bundled Python runtime is missing. Please reinstall SpektraStudio.");
        return 2;
    }

    SetEnvironmentVariableW(L"QT_API", L"pyside6");
    SetEnvironmentVariableW(L"PYTHONNOUSERSITE", L"1");
    SetEnvironmentVariableW(L"PYTHONUTF8", L"1");

    DWORD path_length = GetEnvironmentVariableW(L"PATH", nullptr, 0);
    std::wstring old_path(path_length, L'\0');
    if (path_length > 0) {
        GetEnvironmentVariableW(L"PATH", old_path.data(), path_length);
        if (!old_path.empty() && old_path.back() == L'\0') {
            old_path.pop_back();
        }
    }
    const std::wstring bundled_path = runtime_dir.wstring() + L";" +
        (runtime_dir / L"DLLs").wstring() + L";" + qt_dir.wstring() + L";" + old_path;
    SetEnvironmentVariableW(L"PATH", bundled_path.c_str());

    std::wstring command = quote(pythonw.wstring()) + L" -m spektrafilm_gui.app";
    std::vector<wchar_t> mutable_command(command.begin(), command.end());
    mutable_command.push_back(L'\0');

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};
    const BOOL created = CreateProcessW(
        pythonw.c_str(),
        mutable_command.data(),
        nullptr,
        nullptr,
        FALSE,
        CREATE_UNICODE_ENVIRONMENT,
        nullptr,
        app_dir.c_str(),
        &startup,
        &process
    );
    if (!created) {
        show_error(L"SpektraStudio could not start. Windows error: " + std::to_wstring(GetLastError()));
        return 3;
    }

    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return 0;
}
