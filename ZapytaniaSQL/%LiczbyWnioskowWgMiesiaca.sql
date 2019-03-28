select miesiac, avg(procent_udzial_miesiaca)
from (
       select rok,
              miesiac,
              liczba_wnioskow,
              sum(liczba_wnioskow) over (partition by rok),
              round(liczba_wnioskow / sum(liczba_wnioskow) over (partition by rok) * 100, 2) as procent_udzial_miesiaca
       from (
              select extract(year from w.data_utworzenia)  as rok,
                     extract(month from w.data_utworzenia) as miesiac,
                     count(w.id)                           as liczba_wnioskow
              from wnioski w
                     left join analizy_wnioskow aw on w.id = aw.id_wniosku
              where extract(year from w.data_utworzenia) <> 2018
              group by 1, 2) d1
     ) d2
group by d2.miesiac
order by d2.miesiac;
