MISC=$(wildcard misc/*)
X11=$(wildcard X/*)
SH=$(wildcard shell/*)

all: x11 misc vim shell config

shell: $(SH);
	@for file in $(SH); do \
	    echo "linking $$file"; \
	    ln -sf $(PWD)/$$file $(HOME)/.$$(basename $$file); \
	done

x11: $(X11);
	@for file in $(X11); do \
	    echo "linking $$file"; \
	    ln -sf $(PWD)/$$file $(HOME)/.$$(basename $$file); \
	done

misc: $(MISC);
	@for file in $(MISC); do \
	    echo "linking $$file"; \
	    ln -sf $(PWD)/$$file $(HOME)/.$$(basename $$file); \
	done

vim: $(PWD)/vim;
	@echo "linking vim"
	@ln -sf $(PWD)/vim $(HOME)/.vim

config: $(PWD)/config;
	@echo "linking config"
	@ln -sf $(PWD)/config $(HOME)/.config

clean: ;
	@rm -rf $(HOME)/.vim
	@rm -rf $(HOME)/.config
	@rm -rf $(HOME)/.xmonad

.PHONY: all shell x11 misc vim config clean
