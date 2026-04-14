# Maintainer script — regenerate Artifacts.toml when the data release changes.
# Run manually:  julia scripts/update_artifact.jl
# NOT in deps/build.jl to avoid automatic execution by Pkg.build().

using Pkg, Pkg.Artifacts
using Tar, Inflate, SHA

function main()
    # URL and hash of the data tarball
    url = "https://github.com/s-celles/unique-names-data/releases/download/v0.2.0/unique-names-data.tar.gz"
    tarball_sha256 = "9ad9f2b6cd3bf56045a3faa2db6fd28fb0183defca4581bb4db6e0e109d536d9"

    # Create the artifact by downloading and unpacking the tarball
    artifact_hash = create_artifact() do artifact_dir
        # Download the tarball to a temp location (outside artifact_dir)
        tarball_path = joinpath(tempdir(), "unique-names-data.tar.gz")
        Pkg.PlatformEngines.download(url, tarball_path)

        # Verify the hash
        calculated_hash = bytes2hex(sha256(open(tarball_path)))
        if calculated_hash != tarball_sha256
            error("Tarball hash mismatch. Expected $tarball_sha256, got $calculated_hash")
        end

        # Extract directly into artifact_dir (archive has data/, datapackage.json, etc. at root)
        Tar.extract(IOBuffer(inflate_gzip(read(tarball_path))), artifact_dir)
    end

    # Bind the artifact to the Artifacts.toml file
    bind_artifact!(
        "Artifacts.toml",
        "unique-names-data",
        artifact_hash;
        download_info = [(url, tarball_sha256)],
        lazy = false, # Eager download at install time — offline-friendly
        force = true, # Overwrite existing binding
    )
end

main()

