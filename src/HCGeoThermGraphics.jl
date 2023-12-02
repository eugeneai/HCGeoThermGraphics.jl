module HCGeoThermGraphics
using HCGeoTherm
using CSV
using DataFrames
import Plots as P
using Formatting
using LaTeXStrings

export
    loadCSV, gfxRoot, plot

function loadCSV(fileName :: String) :: DataFrame
    pt = CSV.read(fileName, DataFrame, delim=';', decimal=',')
    pt |> canonifyDF
end

gfxRoot="/var/tmp"

function plot(answer::GTResult,
                  gfxRoot::String,
                  geothermfig::Any,
                  geothermChiSquarefig::Any,
                  geothermOptfig::Any
                  )::Union{GTResult,Nothing}
    plt = P.plot()

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
        Plots.svg(plt, geothermfig)
    end

    if answer.ini.opt
        plt = P.plot()
        (xs, ifu) = chisquare(answer)
        nxsb = minimum(xs)
        nxse = maximum(xs)
        nxs = nxsb:((nxse-nxsb)/100):nxse
        P.plot!(plt, nxs, ifu(nxs), linewith=3, label=L"Cubic BSpline of $\chi^2$",)
        P.plot!(plt, xs, ifu(xs), seriestype=:scatter,
              label=L"$\chi^2$", markercolor = :green)

        miny = chisquareGT(answer.GT_opt, answer.D)
        minx = answer.GT_opt.q0[1]

        P.plot!(plt, [minx], [miny], seriestype=:scatter,
              markercolor = :red,
              label=format(L"Appox. $\min\quad {{q_0}}={}$", minx),
              legend=:top)

        P.xlabel!(L"$q_0$ value")
        P.ylabel!(L"$\chi^2$")

        if typeof(geothermChiSquarefig) == String
            _savefig(plt, gfxRoot * "/" * geothermChiSquarefig)
        else
            P.svg(plt, geothermChiSquarefig)
        end

        plt = undef

        # print("Compiling for an optimal q0\n")

        q0 = convert(Float64, minx)         # [mW/m^2] surface heat flow

        ai = answer.ini

        gpOpt = GTInit([q0], ai.D, ai.zbot, ai.zmax, ai.dz, ai.P, ai.H, ai.iref, false)

        # answero = userComputeGeotherm(gpOpt, answer.D)

        plt = P.plot()

        P.plot!(plt, answer.D.T_C, answer.D.D_km,
              seriestype=:scatter, label="Measurements")
        P.xlabel!(L"Temperature ${}^\circ$C");
        P.ylabel!("Depth [km]");
        P.ylims!(0, answer.ini.zmax)
        P.xlims!(0, ceil(maximum(answer.GT_opt.T)/100)*100+100)

        foreach(plt_gt, [answer.GT_opt])
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
