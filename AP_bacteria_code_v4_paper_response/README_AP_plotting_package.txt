AP paper plotting package

Files

1. post/plot_AP_profiles_paper.m
   New post-processing plotting script. It reads data/AP_profiles/AP_profiles.mat
   and generates paper-style PDF and PNG figures in post/figures.

2. runs/run_AP_profiles.m
   The original run script uploaded in this conversation. It is included only
   for reference and has not been modified.

Usage in MATLAB

First run the original simulation driver:

    run_AP_profiles

Then run the new plotting script:

    plot_AP_profiles_paper

Expected output

    post/figures/AP_profiles_paper.pdf
    post/figures/AP_profiles_paper.png
    post/figures/AP_error_paper.pdf
    post/figures/AP_error_paper.png
    post/figures/AP_speed_paper.pdf
    post/figures/AP_speed_paper.png

Notes

The plotting script does not depend on the variable named Tfinal saved by
run_AP_profiles. It reads macro, kins, eps_list, snap_times, err_snap, and
err_final from AP_profiles.mat. If err_snap or err_final is missing, it
recomputes the errors from the saved density snapshots.
