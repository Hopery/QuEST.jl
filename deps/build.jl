expert = haskey(ENV, "QUEST_EXPERT") && ENV["QUEST_EXPERT"] == "1" ? true : false 

# Execute commands to build QuEST
function _auxBuild(makePrecision::Int,precision::String,isWindows::Bool)::Nothing
    mkdir("build"*precision)
    cd("build"*precision)

    isWindows ? wait(run(`cmake -DPRECISION=$makePrecision .. -G "MinGW Makefiles"`)) :
                wait(run(`cmake -DPRECISION=$makePrecision ..`))
    wait(run(`make`))
    cd("..")
end

# Clone repository and build
function build(isWindows::Bool)::Nothing
    run(`git clone https://github.com/QuEST-Kit/QuEST.git`)
    cd("QuEST")
    _auxBuild(1,"32",isWindows)
    _auxBuild(2,"64",isWindows)
    @info "Build successful."
end

if !expert && (!ispath("QuEST") || isempty(readdir("QuEST")))

    if Sys.isunix()
        build(false)
    elseif Sys.iswindows()
        build(true)
    else
        error("OS not supported.")
    end

end
