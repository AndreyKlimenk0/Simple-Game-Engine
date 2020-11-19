#ifndef BASE_RENDER_H
#define BASE_RENDER_H

#include <d3d11.h>

#include "../win32/win_local.h"

#if defined(DEBUG) | defined(_DEBUG)
	#ifndef HR
	#define HR(x) x
	#endif 
#else 
	#ifndef HR
	#define HR(x) x
	#endif
#endif

#define RELEASE_COM(x) { if(x){ x->Release(); x = 0; } }

struct Direct3D_State {
	ID3D11Device *device = NULL;
	ID3D11DeviceContext *device_context = NULL;
	IDXGISwapChain *swap_chain = NULL;
	
	ID3D11RenderTargetView *render_target_view = NULL;
	ID3D11DepthStencilView *depth_stencil_view = NULL;
	ID3D11Texture2D *depth_stencil_buffer = NULL;
	
	UINT quality_levels;
	
	void init(const Win32_State *win32);
	void shutdown();
	void resize(const Win32_State *win32);
};

void render_frame(Direct3D_State *direct3d);

#endif