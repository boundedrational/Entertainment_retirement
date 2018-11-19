/* check out measurement error in the signal quality */



clear
set more 1

global beta = 0.8
global gamma = 0.3


capture program drop onerun
program define onerun, rclass



        drop _all
        set obs 3000
        gen cty = _n
        expand 100
        bys cty: g grid = _n

/* true signal, better signal counties with higher ID */

        gen signal = floor(runiform() + cty/3000)

/* outcome , non linear in TV signal*/
        gen GPA = 100*runiform() + (signal>0.8)*5
/* outcome , linear in TV signal*/
*        gen GPA = 100*runiform() + signal*10


/* different agregation */
        g avg_sig = signal
        g median_sig = signal
        g dummy_sig = (signal>0.8)

        collapse (median) median_sig (mean) avg_sig GPA dummy_sig, by(cty)

        reg GPA median_sig
        return scalar beta_median = _b[median_sig]

        reg GPA dummy_sig
        return scalar beta_dummy = _b[dummy_sig]

        reg GPA avg_sig
        return scalar beta_mean = _b[avg_sig]

        g avg_on_sign = (avg_sig>0.8)
        reg GPA avg_on_sign
        return scalar beta_avg_on = _b[avg_on_sign]


        end

simulate beta_mean = r(beta_mean) beta_median = r(beta_median) beta_dummy = r(beta_dummy) beta_avg_on = r(beta_avg_on), reps(100): onerun


sum
set more 0


