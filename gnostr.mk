gnostr-tui:### 	gnostr-tui
	cargo install --bins --path alacritty
	gnostr --working-directory $(PWD) --cmd gnostr-tui
	gnostr --repo $(PWD) --cmd gnostr-tui
	gnostr --repo $(shell echo `pwd`) --cmd gnostr-tui
