function y = phi_response(z, p)
switch lower(p.phi_type)
    case 'sign'
        y = -sign(z);
    case 'linear'
        y = -z;
    otherwise
        y = -tanh(z/max(p.phi_delta, eps));
end
end
