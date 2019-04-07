--Liczba wnioskow wg dni - TABELA REFERENCYJNA
WITH AO_Cnt AS (
     select
       to_char(data_wysylki, 'YYYY') AS ROK,
       to_char(data_wysylki, 'Q') AS KWARTAL,
       to_char(data_wysylki, 'MM') AS MIESIAC,
       to_char(data_wysylki, 'WW') AS TYDZIEN,
       to_char(data_wysylki, 'DD') AS DZIEN,
       to_char(data_wysylki, 'ID') AS DZIEN_TYGODNIA,
       count(distinct w.id) AS LiczbaWnioskow
from wnioski_poprawne w
join analiza_operatora ap
    on w.id = ap.id_wniosku
where to_char(data_wysylki, 'YYYY') BETWEEN '2014' AND '2017'
group by 1,2,3,4,5,6
order by 1 desc)


--Liczba wnioskow wg lat
/*, W_ROK AS (
select distinct
       ROK,
       sum(LiczbaWnioskow) over (partition by rok) as LiczbaWnioskow
from AO_Cnt
order by 1 desc,2 desc)
SELECT *,
       ROUND(100 * LiczbaWnioskow / sum(LiczbaWnioskow) OVER (RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),0) AS "%Total",
       ROUND(100 * ((LiczbaWnioskow / (lag(LiczbaWnioskow) over (order by rok))) - 1),0) AS "%YoY"
       FROM W_ROK;
--Najwieksza liczba wnioskow wystapila w 2015 roku
*/

--Liczba wnioskow w miesiacu z podzialem na rok
/*, RokMiesiac AS (
select distinct
       ROK,
       MIESIAC,
       sum(LiczbaWnioskow) over (partition by rok, MIESIAC) as LiczbaWnioskow

from AO_Cnt
order by 1 desc,2 desc)
select *,
       100*Round(LiczbaWnioskow / (sum(LiczbaWnioskow) over (partition by rok range between unbounded preceding and unbounded following)),2) as "%Total(oddzielnie dla roku)",
       ROUND(100*((liczbawnioskow / lag(liczbawnioskow) over (order by rok, miesiac)) - 1),0) AS "%MoM"
from RokMiesiac;
*/

--Liczba wnioskow w miesiacu
/*
select distinct
       MIESIAC,
       sum(LiczbaWnioskow) over (partition by MIESIAC) as LiczbaWnioskow,
       100*Round((sum(LiczbaWnioskow) over (partition by MIESIAC)) / (sum(LiczbaWnioskow) over ()),2) as "%Total"
from AO_Cnt
order by 1 desc;
--Zwiekszona liczba wnioskow wystepuje w miesiacach wakacyjnych - lip, sie, wrz
*/


--Liczba wnioskow wg dni tygodnia
select distinct
       dzien_tygodnia,
       sum(LiczbaWnioskow) over (partition by DZIEN_TYGODNIA) as LiczbaWnioskow,
       100 * ROUND ((sum(LiczbaWnioskow) over (partition by DZIEN_TYGODNIA))
                / (sum(LiczbaWnioskow) over ()),2) AS "%Total"
from AO_Cnt
order by 1;
--Wiecej wnioskow pojawia sie w dni pracujace pon-pt niz w weekend, ale zaden dzien pracujacy nie jest wyrozniony

