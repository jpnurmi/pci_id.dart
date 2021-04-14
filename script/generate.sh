#!/bin/sh

path=$(realpath "$(dirname $0)/..")

(cd $path && dart run tool/generator.dart data/pci.ids -o lib/src/pci_id.g.dart && dartfmt -w lib/src/pci_id.g.dart)
