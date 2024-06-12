# https://weblate.org/en/

ALL_LOCALES := en_US.po es_MX.po fr_FR.po zh_CH.po

# Update all locales from the 'messages.pot' template
.PHONY: all
all: $(ALL_LOCALES)

# Generate a new locale file from the template
.PHONY: generate
generate:
ifndef LOCALE
	$(error LOCALE not specified to generate)
endif
	msginit --no-translator --input=messages.pot --locale=$(LOCALE)

# Update the locale from the 'messages.pot' template
$(ALL_LOCALES): messages.pot
	msgmerge --update --backup=none $@ $<
