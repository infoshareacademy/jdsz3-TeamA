
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
---- iloc wniskow w analizie w danej dacie - obcizenie praca
with wnioski_po_datach as (
select w.id,
       to_char(w.data_utworzenia,'YYYY-MM-DD') as data_utworzenia,
       to_char(aw.data_zakonczenia,'YYYY-MM-DD') as data_zakonczenia
from wnioski_poprawne w
join analizy_wnioskow aw
on w.id = aw.id_wniosku
where     to_char(w.data_utworzenia,'YYYY') not in ('2013','2018')
    ),
     obciazenie_dnia as (
select dda.dzien, count(wpd.id)
from wnioski_po_datach  wpd
left join  dni_do_analizy dda on  to_char(dda.dzien,'YYYY-MM-DD') between   wpd.data_utworzenia and  wpd.data_zakonczenia
--where wpd.id = '2005221'
group by dda.dzien
order by dda.dzien desc)

select *
from obciazenie_dnia;


-- rozkad wedug godzin utworzenia wnioskow
select godzina,
       ilosc_wn_utworzonych,
       round(ilosc_wn_utworzonych/
       sum(ilosc_wn_utworzonych) over (partition by 1)*100,2) as udzial_godziny

from (
         select extract(hour from w.data_utworzenia) as godzina,

                count(w.id)                      as ilosc_wn_utworzonych
         from wnioski w
         group by extract(hour from w.data_utworzenia)
     ) d1
;
