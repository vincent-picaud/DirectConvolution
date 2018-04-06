export UDWT_Filter_Haar, UDWT_Filter_Starck2
export ϕ_filter,ψ_filter,tildeϕ_filter,tildeψ_filter,ϕ_offset,ψ_offset,tildeϕ_offset,tildeψ_offset
export udwt, scale, inverse_udwt!, inverse_udwt

import Base: length

#+UDWT_Filter,TODO
#
# Abstract type defining the $\phi$, $\psi$, $\tilde{\phi}$ and
# $\tilde{\psi}$ filters associated to an undecimated biorthogonal
# wavelet transform
#
# - [ ] TODO must use LinearFilter struct
abstract type UDWT_Filter_Biorthogonal{T<:Number} end

#+UDWT_Filter
ϕ_filter(c::UDWT_Filter_Biorthogonal) = c._ϕ_filter
#+UDWT_Filter
ψ_filter(c::UDWT_Filter_Biorthogonal) = c._ψ_filter
#+UDWT_Filter
tildeϕ_filter(c::UDWT_Filter_Biorthogonal) = c._tildeϕ_filter
#+UDWT_Filter
tildeψ_filter(c::UDWT_Filter_Biorthogonal) = c._tildeψ_filter
#+UDWT_Filter
ϕ_offset(c::UDWT_Filter_Biorthogonal) = c._ϕ_offset
#+UDWT_Filter
ψ_offset(c::UDWT_Filter_Biorthogonal) = c._ψ_offset
#+UDWT_Filter
tildeϕ_offset(c::UDWT_Filter_Biorthogonal) = c._tildeϕ_offset
#+UDWT_Filter
tildeψ_offset(c::UDWT_Filter_Biorthogonal) = c._tildeψ_offset

#+UDWT_Filter
#
# A specialization of UDWT_Filter_Biorthogonal for *orthogonal* filters.
#
#
# For orthogonal filters we have: $\phi=\tilde{\phi}$ and $\psi=\tilde{\psi}$
# 
abstract type UDWT_Filter{T<:Number} <: UDWT_Filter_Biorthogonal{T}
end

#+UDWT_Filter
tildeϕ_filter(c::UDWT_Filter)=ϕ_filter(c)
#+UDWT_Filter
tildeψ_filter(c::UDWT_Filter)=ψ_filter(c)
#+UDWT_Filter
tildeϕ_offset(c::UDWT_Filter)=ϕ_offset(c)
#+UDWT_Filter
tildeψ_offset(c::UDWT_Filter)=ψ_offset(c)



#+UDWT_Filter
# Haar filter
struct UDWT_Filter_Haar{T<:AbstractFloat} <: UDWT_Filter{T}
    _ϕ_filter::SVector{2,T}
    _ψ_filter::SVector{2,T}
    _ϕ_offset::Int
    _ψ_offset::Int

    UDWT_Filter_Haar{T}() where {T<:Real} = new(SVector{2,T}([+1/2 +1/2]),
                                                SVector{2,T}([-1/2 +1/2]),
                                                0,
                                                0)
end



#+UDWT_Filter
# Starck2 filter
#
# Defined by Eq. 6 from http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=4060954
struct UDWT_Filter_Starck2{T<:AbstractFloat} <: UDWT_Filter_Biorthogonal{T}
    _ϕ_filter::SVector{5,T}
    _ψ_filter::SVector{5,T}
    _ϕ_offset::Int
    _ψ_offset::Int
    _tildeϕ_filter::SVector{1,T}
    _tildeψ_filter::SVector{1,T}
    _tildeϕ_offset::Int
    _tildeψ_offset::Int

    UDWT_Filter_Starck2{T}() where {T<:Real} = new(SVector{5,T}([+1/16 +4/16 +6/16 +4/16 +1/16]),
                                                   SVector{5,T}([-1/16 -4/16 +10/16 -4/16 -1/16]),
                                                   2,
                                                   2,
                                                   SVector{1,T}([+1]),
                                                   SVector{1,T}([+1]),
                                                   0,
                                                   0)
end


#+UDWT
# A structure to store 1D UDWT
#
struct UDWT{T<:Number}

    filter::UDWT_Filter_Biorthogonal{T}
    # TODO also store boundary condition

    W::Array{T,2}
    V::Array{T,1}

    UDWT{T}(filter::UDWT_Filter_Biorthogonal{T};
            n::Int=0,
            scale::Int=0) where {T<:Number} =
                new(filter,
                    Array{T,2}(n,scale),
                    Array{T,1}(n))
end

#+UDWT
# Returns max scale
scale(udwt::UDWT)::Int = size(udwt.W,2)
#+UDWT
# Returns initial signal length
length(udwt::UDWT)::Int = size(udwt.W,1)

#+UDWT
#
# Performs an 1D undecimated wavelet transform
#
# $$(\mathcal{W}_{j+1}f)[u]=(\bar{g}_j*\mathcal{V}_{j}f)[u]$$
# $$(\mathcal{V}_{j+1}f)[u]=(\bar{h}_j*\mathcal{V}_{j}f)[u]$$
# 
function udwt(signal::AbstractArray{T,1},filter::UDWT_Filter_Biorthogonal{T};scale::Int=3) where {T<:Number}

    @assert scale>=0

    const boundary = PeriodicBE
    const n = length(signal)
    const udwt_domain = UDWT{T}(filter,n=n,scale=scale)
    const Ωγ = 1:n

    Vs = Array{T,1}(n)
    Vsp1 = Array{T,1}(n)
    Vs .= signal

    for s in 1:scale
        const twoPowScale = 2^(s-1)
        const Wsp1 = @view udwt_domain.W[:,s]
        
        # Computes Vs+1 from Vs
        #
        directConv!(ϕ_filter(filter),
                    ϕ_offset(filter),
                    twoPowScale,

                    Vs,
                    
                    Vsp1,
                    Ωγ,
                      
                    boundary,
                    boundary)

       
        # Computes Ws+1 from Ws
        #
        directConv!(ψ_filter(filter),
                    ψ_offset(filter),
                    twoPowScale,

                    Vs,
                    
                    Wsp1,
                    Ωγ,
                      
                    boundary,
                    boundary)

        @swap(Vs,Vsp1)
        
    end

    udwt_domain.V .= Vs

    return udwt_domain
end

#+UDWT
#
# Performs an 1D *inverse* undecimated wavelet transform
#
# *Caveat:* uses a pre-allocated vector =reconstructed_signal=
#
function inverse_udwt!(udwt_domain::UDWT{T},reconstructed_signal::AbstractArray{T,1}) where {T<:Number}

    @assert length(udwt_domain) == length(reconstructed_signal)

    const boundary = PeriodicBE
    const maxScale = scale(udwt_domain)
    const n = length(reconstructed_signal)
    const Ωγ = 1:n
    const buffer = Array{T,1}(n)
    
    reconstructed_signal .= udwt_domain.V

    
    for s in maxScale:-1:1
        const twoPowScale = 2^(s-1)
        
        # Computes Vs from Vs+1
        #
        directConv!(tildeϕ_filter(udwt_domain.filter),
                    tildeϕ_offset(udwt_domain.filter),
                    -twoPowScale,
                    
                    reconstructed_signal,
                    
                    buffer,
                    Ωγ,
                      
                    boundary,
                    boundary)

        # Computes Ws from Ws+1
        #
        const Ws = @view udwt_domain.W[:,s]

        directConv!(tildeψ_filter(udwt_domain.filter),
                    tildeψ_offset(udwt_domain.filter),
                    -twoPowScale,
                    
                    Ws,
                    
                    buffer,
                    Ωγ,
                      
                    boundary,
                    boundary,
                    accumulate=true)

        for i in Ωγ
            @inbounds reconstructed_signal[i]=buffer[i]
        end
    end
end

#+UDWT
#
# Performs an 1D *inverse* undecimated wavelet transform
#
# *Returns:* a vector containing the reconstructed signal.
#
function inverse_udwt(udwt_domain::UDWT{T})::Array{T,1} where {T<:Number}
    reconstructed_signal=Array{T,1}(length(udwt_domain))
    inverse_udwt!(udwt_domain,reconstructed_signal)
    return reconstructed_signal
end


