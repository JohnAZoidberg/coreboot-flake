default:
    just --list

[no-exit-message]
update *ARGS:
    nix flake update
    @git diff flake.lock | grep "" || (echo 'no changes to flake.lock'; exit 1)
    just --justfile {{ justfile() }} check {{ ARGS }}
    git add flake.lock
    git commit -m 'nix flake update'

check *ARGS:
    nix flake check {{ ARGS }}
