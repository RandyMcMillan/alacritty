-:
	@echo ?
	@awk 'BEGIN {FS = ":.*?###"} /^[a-zA-Z_-]+:.*?###/ {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
?:
	@sed -n 's/^###//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/	/'
-include Makefile

###	:
###help1.0
###	help1.1
###	help1.2
###	help1.3
###		help1.3.a
###	:
###help2.0
###help2.1
###	:
###help1
###help1
###	:
###help1
###	:
