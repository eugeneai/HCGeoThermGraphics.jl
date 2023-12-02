using HCGeoThermGraphics
using HCGeoTherm
using Test

@testset "Main test set" begin
    q0 = 33:0.2:40           # [mW/m^2] surface heat flow
    # q0 = 20:10:100         # [mW/m^2] surface heat flow
    GP = defaultGTInit(q0, true)
    df = loadCSV("data/PTdata.csv")
    answer = computeGeotherm(GP, df)
    plot(answer, gfxRoot,
         "geotherm.svg",
         "geotherm-chisquare.svg",
         "geotherm-opt.svg")
    @test isfile(gfxRoot * "/" * "geotherm.svg")
    @test isfile(gfxRoot * "/" * "geotherm-chisquare.svg")
    @test isfile(gfxRoot * "/" * "geotherm-opt.svg")
end
