# AP bacteria travelling pulse code, v4

This version fixes the macroscopic travelling-pulse comparison and keeps the
clean output layout requested earlier.

## Main fixes

1. The response is now evaluated as

   ```matlab
   phi(eps_response*q_t + v*q_x)
   ```

   with `eps_response = 0` for the limiting macroscopic solver and
   `eps_response = p.eps` for kinetic AP runs.  The previous version used the
   full `q_t + v*q_x` in the macro solver, which corresponds to an order-one
   response time and gives a slower pulse than the analytical macro formula.

2. The sign response is normalized by default.  For the continuous velocity
   grid `V=[-1,1]`, `-sign(y)` alone gives an effective drift
   `chi/2*sign(q_x)`.  The code now multiplies the response by
   `|V|/int_V |v|dv`, so the macro drift is exactly
   `chi*sign(q_x)`, matching the analytical formula.

3. `compare_profile` now plots the mass-normalized analytical profile, as in
   the manuscript.  The peak-normalized curve is still saved in the comparison
   data for diagnostics.

4. Intermediate snapshots are saved under the project-root `data/.../snapshots`
   folders.  The `runs/` folder contains only the case drivers.

## Run

In MATLAB, enter the project root and run

```matlab
startup_AP_bacteria
run_macro_travelling_wave
```

or, for the quick kinetic/macro check,

```matlab
startup_AP_bacteria
run_single_case
```

The macro comparison outputs are written to

```text
data/macro_travelling_wave/
post/figures/profiles.eps
post/figures/compare_profile.eps
```

## Paper-style defaults

The defaults use

```matlab
phi_type = 'sign'
normalize_phi_amplitude = true
rho0_amp = 1
rho0_lambda = 3
```

This gives initial mass about `1/3` on the large domain, matching the vertical
scale of the manuscript figures.  To recover the older mass-one runs, set

```matlab
p.rho0_lambda = 1;
```
