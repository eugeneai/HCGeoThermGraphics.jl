module HCGeoThermGraphics
using HCGeoTherm
using CSV
using DataFrames
import Plots as P
using Format
using LaTeXStrings

export
    loadCSV, gfxRoot, plot

function loadCSV(fileName :: String) :: DataFrame
    pt = CSV.read(fileName, DataFrame, delim=';', decimal=',')
    pt |> canonifyDF
end

gfxRoot="/var/tmp"

function plot(ini::GTInit, df::DataFrame,
                  gfxRoot::String,
                  geothermfig::Any,
                  geothermChiSquarefig::Any,
                  geothermOptfig::Any
                  )::Union{GTResult,Nothing}
    plt = P.plot()

    # ini_free = GTInit(ini, ini.D, ini.zbot, ini.zmax, ini.dz,
    #                   ini.P, ini.H, ini.iref, Set{String}())

    answers = computeGeotherm(ini, df)
    answer = answers["series"]

    P.plot!(plt, answer.D.T_C, answer.D.D_km, seriestype=:scatter, label="Measurements")
    P.xlabel!(L"Temperature ${}^\circ$C");
    P.ylabel!("Depth [km]");
    P.ylims!(0, answer.ini.zmax)
    maxFirst = maximum(first(answer.GT).T)
    maxLast = maximum(last(answer.GT).T)
    max1 = maximum([maxFirst, maxLast])
    P.xlims!(0, ceil(max1/100)*100+100)
    function plt_gt(gt::Geotherm)
        P.plot!(plt, gt.T, gt.z, label=gt.label,
              linewith=3, yflip=true,
              legend=:bottomleft)
    end
    foreach(plt_gt, answer.GT)

    function _savefig(plt, pathName)
        println("SaveFig into " * pathName )
        P.savefig(plt, pathName)
    end

    if typeof(geothermfig) == String
        _savefig(plt, gfxRoot * "/" * geothermfig)
    else
        P.svg(plt, geothermfig)
    end

    if "optimize" in answer.ini.options || "misfits" in answer.ini.options
        plt = P.plot()
        (xs, ifu) = chisquare(answer)
        nxsb = minimum(xs)
        nxse = maximum(xs)
        nxs = nxsb:((nxse-nxsb)/100):nxse
        P.plot!(plt, nxs, ifu(nxs), linewith=3, label="Cubic BSpline of Misfit",)
        P.plot!(plt, xs, ifu(xs), seriestype=:scatter,
              label="Misfit", markercolor = :green)

        answer = answers["optimize"]

        minyr = chisquareGT(answer.GT_opt, answer.D)
        misfit = miny = ifu(answer.GT_opt.q0[1])
        minx = answer.GT_opt.q0[1]

        P.plot!(plt, [minx], [miny], seriestype=:scatter,
              markercolor = :red,
              label=format(L"Appox. $\min\quad {{q_0}}={:.2f}$", minx),
              legend=:top)

        P.xlabel!(L"$q_0$ value" * format("\nMisfit = {:.2f}", misfit))
        P.ylabel!("Misfit")

        if typeof(geothermChiSquarefig) == String
            _savefig(plt, gfxRoot * "/" * geothermChiSquarefig)
        else
            P.svg(plt, geothermChiSquarefig)
        end

        plt = undef

        # print("Compiling for an optimal q0\n")

        q0 = convert(Float64, minx)         # [mW/m^2] surface heat flow

        ai = answer.ini

        # gpOpt = GTInit([q0], ai.D, ai.zbot, ai.zmax, ai.dz, ai.P, ai.H, ai.iref, Set())

        # answero = userComputeGeotherm(gpOpt, answer.D)

        plt = P.plot()

        P.plot!(plt, answer.D.T_C, answer.D.D_km,
              seriestype=:scatter, label="Measurements")
        P.xlabel!(L"Temperature ${}^\circ$C");
        P.ylabel!("Depth [km]");
        P.ylims!(0, answer.ini.zmax)
        P.xlims!(0, ceil(maximum(answer.GT_opt.T)/100)*100+100)

        if "misfits" in answer.ini.options
            panswer = answers["misfits"]
            foreach(plt_gt, [panswer.GT])
        else
            foreach(plt_gt, [answer.GT_opt])
        end
        if typeof(geothermOptfig) == String
            _savefig(plt, gfxRoot * "/" * geothermOptfig)
            print("Saved " * gfxRoot * "/" * geothermOptfig)
        else
            P.svg(plt, geothermOptfig)
        end
    end
        answer
end

end # module
