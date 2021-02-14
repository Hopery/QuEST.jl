# QuEST.jl/deps/build.jl
# MIT License

#
# This script builds the package.
#


using Clang
using Clang.LibClang.Clang_jll


"""
True, if expert installation has been selected
"""
const EXPERT = haskey(ENV, "QUEST_EXPERT") # && ENV["QUEST_EXPERT"] == "1" ? true : false

"""
Execute commands to build QuEST
"""
function _auxBuild(makePrecision ::Int, precision ::String ; isWindows ::Bool) ::Nothing
    mkdir("build"*precision)
    cd("build"*precision)

    # `run()` with `wait=true` throws an error if anything goes wrong,
    # e.g., non-zero exit status

    if isWindows
        run(`cmake -DPRECISION=$makePrecision .. -G "MinGW Makefiles"`; wait=true)
        libclang_include = joinpath("..","QuEST","include") |> normpath
        libclang_headers = [ joinpath(libclang_include,header)   for header in readdir(libclang_include) if endswith(header, ".h")]
        wc = init(; headers = libclang_headers,
                  output_file = joinpath(@__DIR__, "libclang_api.jl"),
                  common_file = joinpath(@__DIR__, "libclang_common.jl"),
                  clang_includes = vcat(libclang_include, CLANG_INCLUDE),
                  clang_args = ["-I", joinpath(libclang_include, ".."), "-DQuEST_PREC=$(makePrecision)"],
                  header_wrapped = (root, current)->root == current,
                  header_library = x->"libclang",
                  clang_diagnostics = true,
                  )
        run(wc)

    else
        run(`cmake -DPRECISION=$makePrecision ..` ; wait=true)
        libclang_include = joinpath("..","QuEST","include") |> normpath
        libclang_headers = [ joinpath(libclang_include,header)   for header in readdir(libclang_include) if endswith(header, ".h")]
        wc = init(; headers = libclang_headers,
                  output_file = joinpath(@__DIR__, "libclang_api.jl"),
                  common_file = joinpath(@__DIR__, "libclang_common.jl"),
                  clang_includes = vcat(libclang_include, CLANG_INCLUDE),
                  clang_args = ["-I", joinpath(libclang_include, ".."), "-DQuEST_PREC=$(makePrecision)"],
                  header_wrapped = (root, current)->root == current,
                  header_library = x->"libclang",
                  clang_diagnostics = true,
                  )
        run(wc)
    end

    run(`make` ; wait=true)

    cd("..")
end


"""
Clone repository, make, Clang
"""
function build(;isWindows::Bool) ::Nothing
    @info "Cloning QuEST..."
    run(`git clone https://github.com/Ketita/QuEST.git` ; wait=true)
    cd("QuEST")
    @info "Build with 32-bit floats..."
    _auxBuild(1,"32" ; isWindows)
    @info "Build with 64-bit floats..."
    _auxBuild(2,"64" ; isWindows)
    @info "Builds successful."
end

#
# File "main" section
#

if EXPERT
    @warn "Expert installation: Make sure the libraries `libQuEST_32` and `libQuEST_64` are loadable."
else
    @warn "Non-expert installation: Downloading QuEST and building it with default settings"

    if ispath("QuEST") && !isempty(readdir("QuEST"))
        rm("QuEST" ; force=true,recursive=true)
    end

    if Sys.isunix()
        build(isWindows=false)
    elseif Sys.iswindows()
        build(isWindows=true)
    else
        error("OS not supported.")
    end
end #^ else

#EOF
