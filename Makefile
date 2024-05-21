SHELL           := /bin/bash
DEVNULL         := /dev/null
NIL             :=
EMPTY           := $(NIL)$(NIL)
ASCII           := 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ

SQUID           := squid
PKGS            := $(SQUID) apache2-utils makepasswd
SUPPORT_PKGS    := curl

### Constants ###
PROXY_PORT      := 3128
HTPASSWD_FILE   := /etc/squid/.htpasswd
BASIC_AUTH_PROG := /usr/lib/squid/basic_ncsa_auth
PROXY_CONF_FILE := /etc/squid/conf.d/proxy.conf
RANDOM_USER      = $(shell makepasswd --chars 8 --string $(ASCII) | tr [:upper:] [:lower:])
RANDOM_PASSWD    = $(shell makepasswd --chars 16 --string $(ASCII))
PUBLIC_ADDR      = $(shell curl https://api.ipify.org 2> $(DEVNULL))
### End Constants ###

### Helpers ###
SVC             := systemctl
START           := $(SVC) start
STATUS          := $(SVC) status
RESTART         := $(SVC) restart
RELOAD          := $(SVC) reload
ENABLE          := $(SVC) enable
ENABLED         := $(SVC) is-enabled
DISABLE         := $(SVC) disable

pkgadd           = DEBIAN_FRONTEND=noninteractive apt install -y $(1)
pkgdel           = DEBIAN_FRONTEND=noninteractive apt remove -y --purge $(1)
disable          = $(DISABLE) --now $(1)
reload           = $(RELOAD) $(1)
makeurl          = http://$(1):$(2)@$(PUBLIC_ADDR):$(PROXY_PORT)

define enable
$(ENABLED) $(1) || $(ENABLE) $(1); \
$(STATUS) $(1) > $(DEVNULL) && $(RELOAD) $(1) || $(START) $(1)
endef
### End Helpers ###

define PROXY_CONF
auth_param basic program $(BASIC_AUTH_PROG) $(HTPASSWD_FILE)
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
cache deny all
forwarded_for delete
via off
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
endef

all:
	$(info Use command: sudo make install [params])
	$(info Parameters:  save-url=/path/to/file    where to save generated proxy URL)
	$(info $(EMPTY)             user=username             specify proxy user, or use random)
	$(info $(EMPTY)             passwd=password           specify proxy password, or use random)
	$(info Uninstall:   sudo make uninstall)
	$(info Reconfigure: sudo make reconf [params])

.SILENT:
install: pkgs config start
	@echo Done!

reconf: $(PROXY_CONF_FILE) $(HTPASSWD_FILE) config restart
	@echo Done!

pkgs: add = $(filter-out !%,$(PKGS))
pkgs: del = $(patsubst !%,%,$(filter !%,$(PKGS)))
pkgs:
	$(if $(add),$(call pkgadd,$(add) $(SUPPORT_PKGS)))
	$(if $(del),$(call pkgdel,$(del)))

config: /usr/bin/makepasswd
	$(if $(user),,$(eval user := $(RANDOM_USER)))
	$(if $(passwd),,$(eval passwd := $(RANDOM_PASSWD)))
	$(file >$(PROXY_CONF_FILE),$(PROXY_CONF))
	@htpasswd -b -c $(HTPASSWD_FILE) "$(user)" "$(passwd)"
	$(if $(save-url),$(file >$(save-url),$(call makeurl,$(user),$(passwd))))
	$(if $(save-url),@echo "Proxy URL created and saved at '$(save-url)'")

start:
	@echo Starting proxy ...
	$(call enable,$(SQUID))

restart:
	@echo Reloading proxy ...
	$(call reload,$(SQUID))

uninstall: del = $(filter-out !%,$(PKGS))
uninstall:
	rm -f $(PROXY_CONF_FILE)
	rm -f $(HTPASSWD_FILE)
	@echo Stopping proxy ...
	$(call disable,$(SQUID))
	$(if $(del),$(call pkgdel,$(del)))
