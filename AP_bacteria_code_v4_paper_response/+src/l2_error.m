function e = l2_error(rho, rho_ref, grid)
e = sqrt(grid.dx*sum((rho-rho_ref).^2));
end
