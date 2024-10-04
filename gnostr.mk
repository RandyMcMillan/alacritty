gnostr-tui:### 	gnostr-tui
	$(MAKE) cargo-install
	gnostr --working-directory $(PWD) --cmd gnostr-tui
	gnostr --repo $(PWD) --cmd gnostr-tui
	gnostr --repo $(shell echo `pwd`) --cmd gnostr-tui
