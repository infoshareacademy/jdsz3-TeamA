-- Analiza najbardziej pracowitych okresow pod katem rekompensat

-- Wszędzie uwzglednia sie tabele wnioski_poprawione

SELECT *
FROM rekompensaty
LIMIT 10;

SELECT *
FROM szczegoly_rekompensat
LIMIT 10;

-- WNIOSEK:
-- W tabeli rekompensaty znajdują się kolumny data_utworzenia i data_zakonczenia
-- W tabeli szczegoly_rekompensat sa kolumny data_otrzymania i data_utworzenia




----------------------

-- Czy data utworzenia wniosku z tabeli wnioski_poprawione jest wcześniejsza niż data utworzenia z tabeli rekompensaty

SELECT r.data_utworzenia - wp.data_utworzenia
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE wp.data_utworzenia > r.data_utworzenia;

-- WNIOSEK:
-- 19 wnioskow ma błędne daty. Beda one usuniete


----------------------

-- Czy data zakonczenia jest pozniejsza niz data utworzenia w tabeli rekompensaty?


SELECT date_part('day', r.data_zakonczenia - r.data_utworzenia), count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE wp.data_utworzenia < r.data_utworzenia
GROUP BY 1
ORDER BY 1;


-- WNIOSEK:
-- Data utworzenia jest zawsze wczesniej niz data zakonczenia więc dane badane pod tym katem wydaja sie poprawne.
-- W wiekszosci wynikow roznice tych dat wynoszą 0 dni.


----------------------

-- Co oznaczają daty w tabeli szczegoly_rekompensat - data_otrzymania i data_utworzenia?

SELECT date_part('day', sr.data_utworzenia - sr.data_otrzymania), count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
GROUP BY 1
ORDER BY 1;


-- WNIOSEK:
-- W wiekszosci wnioskow data_otrzymania jest wczesniejsza od data_utworzenia
-- Dla 20 wnioskow sytuacja jest odwrotna.

SELECT count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
WHERE sr.data_utworzenia < sr.data_otrzymania;

-- Można bedzie pominac te wnioski klauzula: WHERE sr.data_utworzenia < sr.data_otrzymania


----------------------

-- Ktora date wziac zatem do analiz? Na poczatku mozna zbadac jaka jest roznica
-- miedzy maksymalna data i minialna data z obu tabel

WITH daty AS (
SELECT least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as min_day,
       greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as max_day
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id =r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
WHERE sr.data_utworzenia < sr.data_otrzymania )

SELECT date_part('day', max_day - min_day), count(*)
FROM daty
GROUP BY 1
ORDER BY 1;


WITH daty AS (
SELECT sr.data_utworzenia as sr_data_utworzenia , sr.data_otrzymania as sr_data_otrzymania, least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as min_day,
       greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as max_day
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id =r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
WHERE sr.data_utworzenia < sr.data_otrzymania )

SELECT count(*)
FROM daty;



-- Wydaje sie, ze dla wiekszosci wnioskow roznica ta jest nie wieksza niz 30 dni
-- Warto jednak obliczyc kwantyle


WITH daty AS (
SELECT least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as min_day,
       greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as max_day
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id =r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
WHERE sr.data_utworzenia - sr.data_otrzymania > '0 day')

SELECT unnest(
percentile_disc(array[0.01,0.1,0.25,0.5,0.75,0.8,0.85, 0.9,0.99,0.999,0.9999])
within group (order by max_day - min_day)) as kwantyle,
       unnest(array[0.01,0.1,0.25,0.5,0.75,0.8,0.85,0.9,0.99,0.999,0.9999])
as rzad_kwantylu
FROM daty;

-- WNIOSEK:
-- Dla 90% wynikow roznica miedzy max_day i min_day wynosi 20 dni (mediana wynosi 0 dni
-- Można pominac pozostale 10% wnioskow, ktore wydaja sie byc niepoprawne
-- klauzula: WHERE max_day - min_day < '20 day'



----------------------
-- Ktora date wziac do analizy?
-- Mozna sprawdzic skad glownie pochodzi max_day i min_day.

WITH max AS (
SELECT least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as min_day,
       greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as max_day,
       (CASE
    WHEN greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = r.data_utworzenia THEN 'r.data_utworzenia'
    WHEN greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = r.data_zakonczenia THEN 'r.data_zakonczenia'
    WHEN greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = sr.data_utworzenia THEN 'sr.data_utworzenia'
    WHEN greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = sr.data_otrzymania THEN 'sr.data_otrzymania'
    END) as day
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
WHERE sr.data_utworzenia - sr.data_otrzymania > '0 day')

SELECT day, count(*)
FROM  max
WHERE max_day - min_day < '20 day'
GROUP BY 1;

-- WNIOSEK:
-- max_day glownie pochodzi z data_zakonczenia z tabeli rekompensaty


WITH min AS (
SELECT least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as min_day,
       greatest(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) as max_day,
       (CASE
    WHEN least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = r.data_utworzenia THEN 'r.data_utworzenia'
    WHEN least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = r.data_zakonczenia THEN 'r.data_zakonczenia'
    WHEN least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = sr.data_utworzenia THEN 'sr.data_utworzenia'
    WHEN least(r.data_utworzenia, r.data_zakonczenia, sr.data_utworzenia, sr.data_otrzymania) = sr.data_otrzymania THEN 'sr.data_otrzymania'
    END) as day
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty
WHERE sr.data_utworzenia - sr.data_otrzymania > '0 day')

SELECT day, count(*)
FROM  min
WHERE max_day - min_day < '20 day'
GROUP BY 1;

-- WNIOSEK:
-- max_day glownie pochodzi z data_zakonczenia z tabeli rekompensaty



----------------------
-- Jaki procent wnioskow ma rekompensate?

SELECT count(r.id_wniosku)/count(wp.id)::numeric
FROM wnioski_poprawne wp
LEFT JOIN rekompensaty r on wp.id = r.id_wniosku
FULL JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty;

-- WNIOSEK:
-- Ok 30% wnioskow



----------------------
-- Czy wszystkie wnioski z rekompensat maja szczegoly rekompensat

SELECT count(sr.id_rekompensaty)/count(r.id_wniosku)::numeric
FROM wnioski_poprawne wp
LEFT JOIN rekompensaty r on wp.id = r.id_wniosku
LEFT JOIN szczegoly_rekompensat sr on r.id = sr.id_rekompensaty;

-- WNIOSEK:
-- Ok 57% wnioskow
-- Nie ma wiec sensu brac pod uwage tabeli szczegoly rekompensat


--  Jak sie rozklada roznica data_zakonczenia i data_utworzenia
SELECT unnest(
percentile_disc(array[0.01,0.1,0.25,0.5,0.75,0.8,0.85, 0.9,0.99,0.999,0.9999])
within group (order by r.data_zakonczenia - r.data_utworzenia)) as kwantyle,
       unnest(array[0.01,0.1,0.25,0.5,0.75,0.8,0.85,0.9,0.99,0.999,0.9999])
as rzad_kwantylu
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE wp.data_utworzenia < r.data_utworzenia;

-- WNIOSEK
-- 90% wynikow roznica dat wynosi 0

-- Trzeba zbadac te pozostale 10%

SELECT r.data_utworzenia, r.data_zakonczenia
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE r.data_zakonczenia - r.data_utworzenia > '1 days'
AND wp.data_utworzenia < r.data_utworzenia
ORDER BY 1;

-- WNIOSEK:
-- Większosc (ok 130) wnioskow z tych 10% ma data_utworzenia z '2015-10'.

SELECT count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE r.data_zakonczenia - r.data_utworzenia > '1 days'
AND to_char(r.data_utworzenia, 'YYYY-MM') <> '2015-10'
AND wp.data_utworzenia < r.data_utworzenia;

-- Zostalo wiec jeszcze 23 wnioski, ktore tez pominiemy



SELECT to_char(r.data_utworzenia, 'ID') as dzien_tygodnia, count(*) as liczba_wnioskow
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE r.data_zakonczenia - r.data_utworzenia < '1 day'
AND wp.data_utworzenia < r.data_utworzenia
GROUP BY 1
ORDER BY 2 DESC;



SELECT to_char(r.data_utworzenia, 'YYYY') as rok,
       to_char(r.data_utworzenia, 'MM') as miesiac,
       to_char(r.data_utworzenia, 'DD') as dzien,
       count(*) as liczba_wnioskow
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE r.data_zakonczenia - r.data_utworzenia < '1 day'
AND wp.data_utworzenia < r.data_utworzenia
GROUP BY 1,2,3
ORDER BY 4 DESC;


SELECT count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE r.data_zakonczenia - r.data_utworzenia < '1 day'
AND wp.data_utworzenia < r.data_utworzenia;


SELECT to_char(r.data_utworzenia, 'YYYY') as rok,
       to_char(r.data_utworzenia, 'MM') as miesiac,
       count(*) as liczba_wnioskow
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
GROUP BY 1,2
ORDER BY 3 DESC;




SELECT to_char(r.data_utworzenia, 'YYYY') as rok,
       to_char(r.data_utworzenia, 'MM')as miesiac,
       count(*) as liczba_wnioskow,
       round(count(*) / sum(count(*)) over (partition by to_char(r.data_utworzenia, 'YYYY')) * 100, 2) as procent_udzial_rok
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
GROUP BY 1,2
ORDER BY liczba_wnioskow DESC;



SELECT count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day';



SELECT wp.powod_operatora, count(*)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
AND to_char(r.data_utworzenia, 'YYYY-MM') ='2015-10'
GROUP BY 1;


SELECT to_char(wp.data_utworzenia, 'YYYY') as rok,
       to_char(wp.data_utworzenia, 'MM')as miesiac,
       wp.powod_operatora ,
       count(*) as liczba_wnioskow,
       round(count(*) / sum(count(*)) over (partition by wp.powod_operatora) * 100, 2) as procent_udzial_powod
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
GROUP BY 1, 2, 3
HAVING wp.powod_operatora = 'strajk'
ORDER BY procent_udzial_powod DESC;


WITH strajk
 AS (
SELECT to_char(r.data_utworzenia, 'YYYY-MM') as datas,
       wp.powod_operatora as powod, count(*) as liczba_wnioskow
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND to_char(wp.data_utworzenia, 'YYYY') <> '2018' AND to_char(wp.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
GROUP BY 1, 2
HAVING wp.powod_operatora = 'strajk'
),
wszystkie_powody as
(
SELECT to_char(r.data_utworzenia, 'YYYY-MM') as datawp,
       count(*) as liczba_wnioskow_all
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND to_char(wp.data_utworzenia, 'YYYY') <> '2018' AND to_char(wp.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
GROUP BY 1
)

SELECT datawp, round(liczba_wnioskow / liczba_wnioskow_all::numeric * 100, 2) as procent_udzial_powod
FROM wszystkie_powody wp2
JOIN strajk s on wp2.datawp = s.datas
ORDER BY procent_udzial_powod DESC;


--lata wykres
--rok miesiac wykres
--Y0Y





SELECT to_char(r.data_utworzenia, 'YYYY') as rok,
       to_char(r.data_utworzenia, 'MM') as miesiac,
       to_char(r.data_utworzenia, 'DD') as dzien,
       count(*) as liczba_wnioskow
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE r.data_zakonczenia - r.data_utworzenia < '1 day'
AND wp.data_utworzenia < r.data_utworzenia
GROUP BY 1,2,3
ORDER BY 4 DESC;

SELECT to_char(r.data_utworzenia, 'YYYY-MM-DD') as data, wp.id
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
ORDER BY 2 DESC;


SELECT to_char(r.data_utworzenia, 'YYYY-MM') as data, count(wp.id) as liczba_wnioskow
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
GROUP BY 1
ORDER BY 1;


SELECT avg(r.data_utworzenia - wp.data_utworzenia)
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013'
AND wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day';


SELECT unnest(
percentile_disc(array[0.01,0.1,0.25,0.5,0.75,0.8,0.85, 0.9])
within group (order by r.data_utworzenia - wp.data_utworzenia)) ,
       unnest(array[0.01,0.1,0.25,0.5,0.75,0.8,0.85,0.9])
FROM wnioski_poprawne wp
JOIN rekompensaty r on wp.id = r.id_wniosku
WHERE wp.data_utworzenia < r.data_utworzenia
AND r.data_zakonczenia - r.data_utworzenia < '1 day'
AND to_char(r.data_utworzenia, 'YYYY') <> '2018' AND to_char(r.data_utworzenia, 'YYYY') <> '2013';
