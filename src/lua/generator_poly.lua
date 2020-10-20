function gf_mul(x, y, mod)
	local r = 0

	while y > 0 do
		if bit32.band(y, 1) == 1 then r = bit32.bxor(r, x) end
		y = bit32.rshift(y, 1)
		x = bit32.lshift(x, 1)
		if x > 255 then x = bit32.bxor(x, mod) end
	end
	return r
end

function gf_pow(x, n, mod)
	local r = 1

	for i = 1, n do
		r = gf_mul(r, x, mod)
	end
	return r
end

function polynomial_mul(p, q, mod)
	local r = {}
	for i = 1, #p + #q - 1 do
		r[i] = 0
	end
	for i = 1, #p do
		for j = 1, #q do
			r[i + j - 1] = bit32.bxor(r[i + j - 1], gf_mul(p[i], q[j], mod))
		end
	end
	return r
end

function get_generator_poly(n)
	local g = { 1 }
	for i = 1, n do
		g = polynomial_mul(g, {1, gf_pow(2, i - 1, 285)}, 285)
	end
	return g
end

local generator_poly = get_generator_poly(arg[1] or 10)
for i = 1,#generator_poly do
	print(generator_poly[i])
end
