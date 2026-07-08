PLATFORM ?= v4i

DIRS_SEL := `cat Rules.mk | sed '/\#.*/d' | awk '/=.*$(PLATFORM)/ { print $$1 }'`
DIRS_ALL := `cat Rules.mk | sed '/\#.*/d' | awk '{ print $$1 }'`

all:
	@for DIR in $(DIRS_SEL); do $(MAKE) -C $$DIR || exit; done

clean:
	@for DIR in $(DIRS_ALL); do $(MAKE) -C $$DIR clean; done

.PHONY: all clean
