using IterTools

function grid_0(n)
    return hcat([[i] for i in range(0,n+1)]...)
end

function grid_1(n)
    return hcat([[i,i+1] for i in range(0,n)]...)
end

function larGrid(n)
    function larGrid1(d)
        if d==0 
        	return grid_0(n)
        elseif d==1 
        	return grid_1(n) 
        end
    end
    return larGrid1
end

function cart(args)
	return sort(collect(IterTools.product(args...)))
end

function index2addr(shape::Array{Int64,1})
	index2addr(hcat(shape...))
end

function index2addr(shape::Array{Int64,2})
    n = length(shape)
    theShape = append!(shape[2:end],1)
    weights = [prod(theShape[k:end]) for k in range(1,n)]
    function index2addr0(multiIndex)
        return dot(collect(multiIndex), weights) + 1
    end
    return index2addr0
end
       
function binaryRange(n)
	return [bin(k,n) for k in 0:2^n-1]
end

function larVertProd(vertLists)
	coords = [[x[1] for x in v] for v in cart(vertLists)]
   return sortcols(hcat(coords...))
end

function filterByOrder(n)
	terms = [[parse(Int8,bit) for bit in convert(Array{Char,1},term)] for term in binaryRange(n)]
	return [[term for term in terms if sum(term) == k] for k in 0:n]
end

function vertexDomain(n)
	return hcat([k for k in 0:n-1]...)
end

function larImageVerts(shape)
	vertLists = [vertexDomain(k+1) for k in shape]
	vertGrid = larVertProd(vertLists)
	return vertGrid
end

function larCellProd(cellLists)
	shapes = [length(item) for item in cellLists]
	subscripts = cart([collect(range(0,shape)) for shape in shapes])
	indices = hcat([collect(tuple) for tuple in subscripts]...)
	jointCells = Any[]
	for h in 1:size(indices,2)
		index = indices[:,h]
		cell = hcat(cart([cells[k+1] for (k,cells) in zip(index,cellLists)])...)
		append!(jointCells,[cell])
	end
	convertIt = index2addr([ (length(cellLists[k][1]) > 1)? shape+1 : shape for (k,shape) in enumerate(shapes) ])		
	[vcat(map(convertIt, jointCells[j])...) for j in 1:size(jointCells,1)]
	#[map(convertIt, jointCells[j]) for j in 1:size(jointCells,1)]
end

function larGridSkeleton(shape)
    n = length(shape)
    function larGridSkeleton0(d)
        components = filterByOrder(n)[d+1]
        mymap(arr) = [arr[:,k]  for k in 1:size(arr,2)]
        componentCellLists = [ [ mymap(f(x)) for (f,x) in zip( [larGrid(dim) for dim in shape],component ) ]
                              for component in components ]
        out = [ larCellProd(cellLists)  for cellLists in componentCellLists ]
        return vcat(out...)
    end
    return larGridSkeleton0
end

function larCuboids(shape, full=false)
	vertGrid = larImageVerts(shape)
	gridMap = larGridSkeleton(shape)
	if ! full
		cells = gridMap(length(shape))
	else
		skeletonIds = 0:length(shape)
		cells = [ gridMap(id) for id in skeletonIds ]
	end
	return vertGrid, cells
end

shape = (3,2,1)
cubes = larCuboids(shape,true)
print(cubes)

shape = (1,1,1)
cubes = larCuboids(shape,true)
print(cubes)

shape = (10,10,10)
cubes = larCuboids(shape,true)
print(cubes)




using DataStructures


function larModelProduct(twoModels)
    modelOne, modelTwo = twoModels
    larModelProduct(modelOne, modelTwo)
end

function larModelProduct(modelOne, modelTwo)
    (V, cells1) = modelOne
    (W, cells2) = modelTwo

    k = 1
    vertices = OrderedDict()
    for v in V
        for w in W
            id = [v;w]
            if haskey(vertices, id) == false
                vertices[id] = k
                k = k + 1
            end
        end
    end

    cells = []
    for c1 in cells1
        for c2 in cells2
            cell = []
            for vc in c1
                for wc in c2 
                    push!(cell, vertices[[V[vc];W[wc]]] )
                end
            end
            push!(cells, cell)
        end
    end

    vertexmodel = []
    for v in keys(vertices)
        push!(vertexmodel, v)
    end

    return (vertexmodel, cells)
end


geom_0 = [[x] for x=0.:10]
topol_0 = [[i,i+1] for i=1:9]
geom_1 = [[0.],[1.],[2.]]
topol_1 = [[1,2],[2,3]]
model_0 = (geom_0,topol_0)
model_1 = (geom_1,topol_1)

model_2 = larModelProduct(model_0, model_1)
model_3 = larModelProduct(model_2, model_1)


using PyCall
@pyimport larlib as p

function larView(V::Array{Any,1},CV::Array{Any,1})
	V = hcat(V[1],V...)
	W = [Any[V[h,k] for h=1:size(V,1)] for k=1:size(V,2)]
	p.VIEW(p.STRUCT(p.MKPOLS(PyObject([W,CV,[]]))))
end


function larExplodedView(V::Array{Any,1},CV::Array{Any,1})
	V = hcat(V[1],V...)
	W = [Any[V[h,k] for h=1:size(V,1)] for k=1:size(V,2)]
	p.VIEW(p.EXPLODE(1.2,1.2,1.2)(p.MKPOLS(PyObject([W,CV,[]]))))
end

larView(model_3...)
larExplodedView(model_3...)
larExplodedView(model_3[1],model_3[2])


function larExplodedView(V::Array{Any,2},CV::Array{Any,2})
	Z = hcat(V[:,1],V)
	W = [Any[Z[h,k] for h=1:size(Z,1)] for k=1:size(Z,2)]
	CV = hcat(CV'...)
	CW = [Any[CV[h,k] for h=1:size(CV,1)] for k=1:size(CV,2)]
	p.VIEW(p.EXPLODE(1.2,1.2,1.2)(p.MKPOLS(PyObject([W,CW,[]]))))
end

function larExplodedView(V::Array{Int64,2},CV::Array{Array{Int64,1},1})
	Z = hcat(V[:,1],V)
	W = [Any[Z[h,k] for h=1:size(Z,1)] for k=1:size(Z,2)]
	CW = [Any[cell[h] for h=1:length(cell)] for cell in CV]
	p.VIEW(p.EXPLODE(1.2,1.2,1.2)(p.MKPOLS(PyObject([W,CW,[]]))))
end

shape = (40,20,10)
cubes = larCuboids(shape,true)
V,FV = cubes[1],cubes[2][3]
larExplodedView(V,FV)

