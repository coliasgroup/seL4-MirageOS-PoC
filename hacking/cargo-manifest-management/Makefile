tool = ../../rust-sel4/hacking/cargo-manifest-management/tool

manifest_path := $(tool)/Cargo.toml

blueprint := blueprint.json

run := cd $(tool) && cargo run -p manage-cargo-manifests --

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf tool/target $(blueprint)

.PHONY: $(blueprint)
$(blueprint):
	nix-build -A blueprintJSON --out-link $@

.PHONY: update
update: $(blueprint)
	$(run) --blueprint $(abspath $<)
