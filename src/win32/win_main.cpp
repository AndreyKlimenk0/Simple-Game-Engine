#include "win_local.h"
#include "../render/base.h"

bool game_end = false;

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

void create_and_show_window(Win32_State *win32, int nCmdShow)
{
	const char CLASS_NAME[] = "Sample Window Class";

	WNDCLASS wc = { };

	wc.lpfnWndProc = WindowProc;
	wc.hInstance = win32->hinstance;
	wc.lpszClassName = CLASS_NAME;

	RegisterClass(&wc);

	HWND hwnd = CreateWindowEx(0, CLASS_NAME,"Learn to Program Windows", WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, win32->hinstance, NULL
	);

	if (hwnd == NULL) {
		return;
	}
	ShowWindow(win32->window, nCmdShow);
	win32->window = hwnd;

	HDC window_dc = GetDC(win32->window);
	win32->window_width = GetDeviceCaps(window_dc, HORZRES);
	win32->window_height = GetDeviceCaps(window_dc, VERTRES);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR pCmdLine, int nCmdShow)
{
	Win32_State win32_state;

	//create_console(&win32_state);
	win32_state.hinstance = hInstance;
	create_and_show_window(&win32_state, nCmdShow);


	Direct3D_State direct3d;
	direct3d.init(&win32_state);

	MSG msg = { };
	while (!game_end) {
		if (PeekMessage(&msg, win32_state.window, 0, 0, PM_REMOVE)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		render_frame(&direct3d);
	}
	direct3d.shutdown();
	return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg) {
		case WM_DESTROY: {
			game_end = true;
			PostQuitMessage(0);
			return 0;
		}
		case WM_PAINT: {
			PAINTSTRUCT ps;
			HDC hdc = BeginPaint(hwnd, &ps);
			FillRect(hdc, &ps.rcPaint, (HBRUSH)(COLOR_WINDOW + 1));
			EndPaint(hwnd, &ps);
			return 0;
		}
	}
	return DefWindowProc(hwnd, uMsg, wParam, lParam);
}