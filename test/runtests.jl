using ReverseDiffTape 
using Base.Test

# write your own tests here
using FactCheck

## Test for forward function evaluation
facts("Function evaluataion ") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x, 1.1)
	x2 = AD_V(x, 2.2)
	x3 = AD_V(x, 3.3)
	p1 = AD_P(p, 1)
	p2 = AD_P(p, 2)
	c = sin(x1)+cos(x2^p2) * p1 - x3*p2
	tt = tapeBuilder(c.data)
	val = feval(tt,x,p)
	@fact sin(1.1)+cos(2.2^2)*1-3.3*2 --> val
end

facts("Reverse gradient sin(a)*cos(b) ") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	a = AD_V(x,1.1)
	b = AD_V(x,2.2)
	c=sin(a)*cos(b)
	tt = tapeBuilder(c.data)
	grad = Array{Float64,1}(length(x))
	grad_reverse(tt,x,p,grad)
	I = Array{IDX_TYPE,1}()
	grad_structure(tt,I)
	@fact length(I) --> 2
	@fact length(grad) --> length(x)
	@fact grad[1] --> cos(2.2)*cos(1.1)
	@fact grad[2] --> sin(1.1)*(-sin(2.2))
end

facts("Reverse gradient a^3") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	a = AD_V(x,1.1)
	b = AD_P(p,3)
	c = a^b
	tt = tapeBuilder(c.data)
	grad = Array{Float64,1}(length(x))
	grad_reverse(tt,x,p,grad)
	@fact length(grad) --> length(x)
	@fact grad[1] --> 3*1.1^2
end

facts("Reverse gradient x1*x2*x3*x4") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	x3 = AD_V(x,3.3)
	x4 = AD_V(x,4.4)
	c = x1*x2*x3*x4
	tt = tapeBuilder(c.data)
	grad = Array{Float64,1}(length(x))
	grad_reverse(tt,x,p,grad)
	@fact length(grad) --> length(x)
	@fact grad[1] --> 2.2*3.3*4.4
	@fact grad[2] --> 1.1*3.3*4.4
	@fact grad[3] --> 1.1*2.2*4.4
	@fact grad[4] --> 1.1*2.2*3.3	
end

facts("Reverse gradient sin(x1*x2*x3*x4)") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	x3 = AD_V(x,3.3)
	x4 = AD_V(x,4.4)
	c = sin(x1*x2*x3*x4)
	tt = tapeBuilder(c.data)
	grad = Array{Float64,1}(length(x))
	grad_reverse(tt,x,p,grad)
	@fact length(grad) --> length(x)
	@fact grad[1] --> cos(1.1*2.2*3.3*4.4)*2.2*3.3*4.4
	@fact grad[2] --> cos(1.1*2.2*3.3*4.4)*1.1*3.3*4.4
	@fact grad[3] --> roughly(cos(1.1*2.2*3.3*4.4)*1.1*2.2*4.4)
	@fact grad[4] --> cos(1.1*2.2*3.3*4.4)*1.1*2.2*3.3	
end


facts("Reverse gradient cos(x1*x2*x3*x4)") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	x3 = AD_V(x,3.3)
	x4 = AD_V(x,4.4)
	c = cos(x1*x2*x3*x4)
	tt = tapeBuilder(c.data)
	grad = Array{Float64,1}(length(x))
	grad_reverse(tt,x,p,grad)
	@fact length(grad) --> length(x)
	@fact grad[1] --> -sin(1.1*2.2*3.3*4.4)*2.2*3.3*4.4
	@fact grad[2] --> -sin(1.1*2.2*3.3*4.4)*1.1*3.3*4.4
	@fact grad[3] --> roughly(-sin(1.1*2.2*3.3*4.4)*1.1*2.2*4.4)
	@fact grad[4] --> -sin(1.1*2.2*3.3*4.4)*1.1*2.2*3.3	
end



facts("Hessian EP algorithm x1^2") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	p2 = AD_P(p,2)
	c = x1^p2
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	h = EdgeSet{Int,Float64}()
	hess_structure_lower(tt,eset)
	hess_reverse(tt,x,p,h)
	@fact length(eset) --> 1
	@fact haskey(eset,1) --> true
	@fact length(eset[1]) --> 1
	@fact h[1][1] --> 2.0
end

function count(eset::Dict{Int,Set{Int}})
	c = 0
	for i in eset
		c+=length(i[2])
	end
	return c
end


facts("Hessian EP algorithm x1^2*x2^2") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	p2 = AD_P(p,2)
	c = x1^p2*x2^p2
	tt = tapeBuilder(c.data)

	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{Int,Float64}()
	hess_reverse(tt,x,p,h)
	
	@fact count(eset) --> 3
	@fact h[1][1] --> 2.2*2.2*2
	@fact h[2][1] --> 2*1.1*2*2.2
	@fact h[2][2] --> 1.1*1.1*2 
end

facts("Hessian EP algorithm sin(x1)") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	c = sin(x1)
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 1
	@fact h[1][1] --> -sin(1.1) 
end


facts("Hessian EP algorithm cos(x1)") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	c = cos(x1)
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 1
	@fact h[1][1] --> -cos(1.1) 
end

facts("Hessian EP algorithm x1*x2") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	c = x1*x2
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 1
	@fact h[2][1] --> 1.0
end


facts("Hessian EP algorithm sin(x1*x2)") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	c = sin(x1*x2)
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 3
	@fact h[2][1] --> cos(1.1*2.2) - 1.1*2.2*sin(1.1*2.2)
	@fact h[1][1] --> -2.2^2*sin(1.1*2.2)
	@fact h[2][2] --> -1.1^2*sin(1.1*2.2)
end

facts("Hessian EP algorithm cos(sin(x1))") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	c = cos(sin(x1))
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 1
	@fact h[1][1] --> sin(sin(1.1))*sin(1.1) - cos(sin(1.1))*(cos(1.1)^2)
end


facts("Hessian EP algorithm cos(sin(x1*x2))") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	c = cos(sin(x1*x2))
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 3
	@fact h[1][1] --> roughly(2.2^2*sin(sin(1.1*2.2))*sin(1.1*2.2)-2.2^2*cos(sin(1.1*2.2))*cos(1.1*2.2)^2)
end

facts("Hessian EP algorithm x1*x1") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	c = x1*x1
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 1
	@fact h[1][1] --> 2.0
end

facts("Hessian EP algorithm cos(x1*x2)") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	c = cos(x1*x2)
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 3
	@fact h[1][1] --> -cos(1.1*2.2)*2.2*2.2
	@fact h[2][1] --> -(sin(1.1*2.2)+cos(1.1*2.2)*1.1*2.2)
	@fact h[2][2] -->  -cos(1.1*2.2)*1.1*1.1 
end


facts("Hessian EP algorithm x1*x1*x2*x2") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	x2 = AD_V(x,2.2)
	p2 = AD_P(p,2)
	c = x1*x1*x2*x2
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)
	@fact count(eset) --> 3
	@fact h[1][1] --> 2.2*2.2*2
	@fact h[2][1] --> 2*1.1*2*2.2
	@fact h[2][2] --> 1.1*1.1*2 
end

facts("Hessian EP algorithm x1*x1*x1") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x,1.1)
	p2 = AD_P(p,2)
	c = x1*x1*x1
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)

	@fact count(eset) --> 1
	@fact h[1][1] --> 6*1.1
end

facts("Hessian EP algorithm sin(x1)+cos(x2^2)*1-x3*2") do
	p = Array{Float64,1}()
	x = Array{Float64,1}()
	x1 = AD_V(x, 1.1)
	x2 = AD_V(x, 2.2)
	x3 = AD_V(x, 3.3)
	# p1 = AD_P(p, 1.0)
	p2 = AD_P(p, 2.0)
	# c = sin(x1)+cos(x2^p2) * p1 - x3*p2
	c = sin(x1)+cos(x2^p2) - x3*p2
	tt = tapeBuilder(c.data)
	eset = Dict{Int,Set{Int}}()
	hess_structure_lower(tt,eset)
	h = EdgeSet{IDX_TYPE,Float64}()
	hess_reverse(tt,x,p,h)

	@fact count(eset) --> 2
	@fact h[1][1] --> -sin(1.1)
	@fact h[2][2] --> -2*sin(2.2^2)-4*2.2^2*cos(2.2^2)
end
FactCheck.exitstatus()
