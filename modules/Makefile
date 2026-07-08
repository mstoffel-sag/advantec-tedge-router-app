PLATFORM ?= v4i

DIRS_SEL := `cat Rules.mk | sed '/\#.*/d' | awk '/=.*$(PLATFORM)/ { print $$1 }'`
DIRS_ALL := `cat Rules.mk | sed '/\#.*/d' | awk '{ print $$1 }'`

all:
	@for DIR in $(DIRS_SEL); \
		do $(MAKE) -C $$DIR IMGDIR=../../images/$$DIR || exit; \
		if [ -f $$DIR/CHANGELOG.txt ] && [ -d ../images/$$DIR ]; then \
			cp $$DIR/CHANGELOG.txt ../images/$$DIR/; \
		fi; \
	done

clean:
	@for DIR in $(DIRS_ALL); do $(MAKE) -C $$DIR clean; done

.PHONY: all clean
