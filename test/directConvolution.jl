@testset "Example α_offset" begin

    α0=LinearFilter(Float64[0,1,0],0)
    α1=LinearFilter(Float64[0,1,0],1)
    β=collect(Float64,1:6)
    γ1=directConv(α0,1,β,ZeroPaddingBE,ZeroPaddingBE)
    γ2=directConv(α1,1,β,ZeroPaddingBE,ZeroPaddingBE) 

    @test γ1 ≈ [2.0, 3.0, 4.0, 5.0, 6.0, 0.0]
    @test γ2 ≈ [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

end;


@testset "Adjoint operator" begin

    α=LinearFilter(rand(4),2);
    β=rand(10);

    vβ=rand(length(β))
    d1=dot(directConv(α,-3,vβ,ZeroPaddingBE,ZeroPaddingBE),β)
    d2=dot(directConv(α,+3,β,ZeroPaddingBE,ZeroPaddingBE),vβ)

    
    @test isapprox(d1,d2)

    d1=dot(directConv(α,-3,vβ,PeriodicBE,PeriodicBE),β)
    d2=dot(directConv(α,+3,β,PeriodicBE,PeriodicBE),vβ)

    @test isapprox(d1,d2)

end;


@testset "Convolution commutativity" begin

    α=rand(4);
    β=rand(10);

    v1=zeros(20)
    v2=zeros(20)
    directConv!(α,0,-1,
                β,v1,UnitRange(1,20),ZeroPaddingBE,ZeroPaddingBE)
    directConv!(β,0,-1,
                α,v2,UnitRange(1,20),ZeroPaddingBE,ZeroPaddingBE)

    @test isapprox(v1,v2)

end;

@testset "Interval split" begin

    α=LinearFilter(rand(4),3)
    β=rand(10);

    γ=directConv(α,2,β,MirrorBE,PeriodicBE) # global computation
    Γ=zeros(length(γ))
    Ω1=UnitRange(1:3)
    Ω2=UnitRange(4:length(γ))
    directConv!(α,2,β,Γ,Ω1,MirrorBE,PeriodicBE) # compute on Ω1
    directConv!(α,2,β,Γ,Ω2,MirrorBE,PeriodicBE) # compute on Ω2

    @test isapprox(γ,Γ)

end;
