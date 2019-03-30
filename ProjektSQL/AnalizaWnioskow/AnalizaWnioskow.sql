
--sredni udzial miesiaca we wnioskach z calego roku

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
                  from wnioski_poprawne w
                           left join analizy_wnioskow aw on w.id = aw.id_wniosku
                  where extract(year from w.data_utworzenia) <> 2018
                  group by 1, 2) d1
     ) d2
group by d2.miesiac
order by d2.miesiac
;
--obciazenie dni w roku

select dzien_roku, round(avg(procent_udzial_doy),2) as procent_udzial_doy
from (
         select rok,
                dzien_roku,
                liczba_wnioskow,
                sum(liczba_wnioskow) over (partition by rok),
                round(liczba_wnioskow / sum(liczba_wnioskow) over (partition by rok) * 100, 2) as procent_udzial_doy
         from (
                  select extract(year from w.data_utworzenia)  as rok,
                         extract(doy from w.data_utworzenia) as dzien_roku,
                         count(w.id)                           as liczba_wnioskow
                  from wnioski_poprawne w
                           left join analizy_wnioskow aw on w.id = aw.id_wniosku
                  where extract(year from w.data_utworzenia) <> 2018
                  group by 1, 2) d1
     ) d2
group by d2.dzien_roku
order by 2 desc
;

