# Make a private registry for my Julia packages.

using Pkg
using UUIDs: uuid4


# Find packages in ~/.julia/dev that are remoted to GitHub:

using GitHub
using TOML
import Base64

println("Enter github authentication token:")
github_auth = GitHub.authenticate(readline())

github_me = GitHub.whoami(; auth=github_auth)

github_repos, _ =  GitHub.repos(github_me; auth=github_auth)

# Map from GitHub.Repo to parsed Project.toml file:
parsed_project_files = Dict{GitHub.Repo, Dict{String, Any}}()

# Find my Julia projects on GitHub:
map(
    filter(github_repos) do r
        try
            content_object = GitHub.file(r, "Project.toml"; auth=github_auth)
            @assert content_object.encoding == "base64"
            proj = TOML.parse(String(Base64.base64decode(content_object.content)))
            # error if missing:
            proj["compat"]["julia"]
            parsed_project_files[r] = proj
            true
        catch e
            println("*** $(r.name): $e")
            false
        end
    end) do r
        r.name
    end

# Cherry-picked from the above results:
packages = [
    "AnotherParser.jl"
    "DXFutils.jl"
    "NahaJuliaLib.jl"
    "PanelCutting.jl"
    "PlutoTool.jl"
    "RegistryTools.jl"
    "ShaperOriginDesignLib"
    "Unification.jl"
    "UnitfulCurrency.jl"
    "VectorLogging.jl"
    # "WebBasedWorkspace"
]

cherry_picked_repos = filter(github_repos) do r
    r.name in packages
end

function repoPackageSpec(repo::GitHub.Repo)
    proj = parsed_project_files[repo]
    PackageSpec(;name=proj["name"],
                uuid=proj["uuid"],
                url=repo.clone_url.uri)
end


# Creating a registry file:

Pkg.add("RegistryTools")
using RegistryTools

function ensure_registry()
    registry_file = joinpath(@__DIR__, "Regsitry.toml")
    if isfile(registry_file)
        return registry_file
    end
    registry_data = RegistryTools.RegistryData(
        "NahaJuliaRegistry",
        uuid4(),
        repo=nothing,
        description="A registry of Mark Nahabedian's otherwise unregistered Julia packages.")
    RegistryTools.write_registry(registry_file, registry_data)
    registry_file
end

ensure_registry()


# LocalRegistry requires that each package have a clean checkout for
# development.  I have no clue why it needs to modify the package.

# Pkg.develop would clone the repository for us, but there is noway to
# temporarily override where it putrs the local copy.  Since I have
# active working copies in ~/.julia.dev, I need to create a directory
# for package clones and clone the packages myself.

function package_staging_dir()
    p = joinpath(@__DIR__, "package_staging")
    if !isdir(p)
        mkdir(p)
    end
    p
end

using URIs
# using GitHub   How to clone a repository?

function mydevelop(repo::GitHub.Repo)
    staging = package_staging_dir()
    env = (
        "JULIA_PKG_DEVDIR" => staging,
    )
    u = repo.clone_url
    runlist = [
        "using Pkg",
        "println(ENV[\"JULIA_PKG_DEVDIR\"], '\n', Pkg.devdir())",
        "Pkg.develop(; url=\"$u\", shared=true)"
    ]
    p = run(pipeline(Cmd(Cmd(["julia",
                              "-E", join(runlist, "; ")]);
                         env=env,
                         dir=staging),
                     stdout=Base.stdout,
                     stderr=Base.stderr,
                     );
            wait=true)
    @assert p.exitcode == 0
end


# map(mydevelop(cherry_picked_repos)


# Registering packages:

# Pkg.add("LocalRegistry")
# using LocalRegistry
