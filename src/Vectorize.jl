##===----------------------------------------------------------------------===##
##                                   ACCELERATE.JL                            ##
##                                                                            ##
##===----------------------------------------------------------------------===##
##                                                                            ##
##  This file checks for the available frameworks and imports only the        ##
##  frameworks available; it also coordinates access to three frameworks      ##
##  through the unified Vectorize.f() syntax                                  ##
##                                                                            ##
##===----------------------------------------------------------------------===##
module Vectorize

export @vectorize

## FUNCTION DICTIONARY
functions = Dict()

## Function for adding to function dictionary
function addfunction(d::Dict, k, v)
    if k in keys(d)
        append!(d[k], [v])
    else
        d[k] = []
        append!(d[k], [v])
    end
end

## START OSX
## On OS X, check if Accelerate can be found - future proofing
@osx? (ACCELERATE = true) : (ACCELERATE = false)
if ACCELERATE == true
    if isfile("/System/Library/Frameworks/Accelerate.framework/Accelerate")
        eval(:(include("Accelerate.jl")))
    else
        warn("Unable to locate the Apple Accelerate framework")
    end
end
## END OSX

## Find Yeppp library
libyeppp_ = Libdl.find_library(["libyeppp"])
if libyeppp_ != ""
    const global libyeppp = libyeppp_
else
    currdir = @__FILE__
    bindir = currdir[1:end-16]*"deps/src/yeppp/binaries/"
    if OS_NAME == :Darwin
        @eval const global libyeppp = bindir*"macosx/x86_64/libyeppp.dylib"
    elseif OS_NAME == :Linux
        @eval const global libyeppp = bindir*"linux/x86_64/libyeppp.so"
    elseif OS_NAME == :Windows
        @eval const global libyeppp = bindir*"windows/amd64/yeppp.dll"
    end
end
if isfile(libyeppp)
    include("Yeppp.jl") # include Yeppp if present
end

## Find VML
const global libvml = Libdl.find_library(["libmkl_vml_avx"], ["/opt/intel/mkl/lib"])
if libvml != ""
    include("VML.jl")
end

# vectorize macro
macro vectorize(ex)
    f = :(Vectorize.$(ex.args[1]))
    arg = ex.args[2]
    return esc(:($f($arg)))
end

# Include optimized functions
include("Functions.jl")

end # module
