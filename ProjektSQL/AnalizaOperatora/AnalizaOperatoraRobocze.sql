-- ### Wiekszosc wnioskow z bledna data zostalo utworzonych 15/05/2015
WITH AO_Cnt AS (
     select
       to_char(data_wysylki, 'YYYY') AS ROK,
       to_char(data_wysylki, 'Q') AS KWARTAL,
       to_char(data_wysylki, 'MM') AS MIESIAC,
       to_char(data_wysylki, 'WW') AS TYDZIEN,
       to_char(data_wysylki, 'DD') AS DZIEN,
       to_char(data_wysylki, 'ID') AS DZIEN_TYGODNIA,
       count(distinct w.id) AS LiczbaWnioskow
--from wnioski_poprawne w
from wnioski w
join analiza_operatora ap
    on w.id = ap.id_wniosku
group by 1,2,3,4,5,6
order by 1 desc)
--Liczba wnioskow w miesiacu z podzialem na rok
select ROK, DZIEN, sum(LiczbaWnioskow) from AO_Cnt
where ROK = '2015' AND MIESIAC = '05'
group by 1,2

--- ### CSV

select distinct
      ao.data_wysylki::date as DATA,
      w.id as ID_WNIOSKU
from wnioski_poprawne w
join analiza_operatora ao
on w.id = ao.id_wniosku
where to_char(ao.data_wysylki, 'YYYY') between '2014' and '2017'