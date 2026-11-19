# الصق هذا الملف كله في خلية واحدة في Google Colab (colab.research.google.com) ثم شغّلها.
# يولّد 659 ملفًا صوتيًا ألمانيًا ويرفعها مباشرة إلى Supabase Storage.
import asyncio, os, subprocess, sys
subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "edge-tts", "requests", "nest_asyncio"])
import edge_tts, requests, nest_asyncio
nest_asyncio.apply()

SUPABASE_URL = "https://xxxx.supabase.co"   # <- رابط مشروعك
SERVICE_KEY  = "ضع_هنا_مفتاح_service_role"     # <- سري! استعمله هنا فقط ولا تشاركه ولا تنشر الدفتر
VOICE = "de-DE-KatjaNeural"                  # بديل: de-DE-ConradNeural

TEXTS = """en
ö
Haus
zett
el
er
eszett
ü
de
ha
ka
u
o
ze
Schule
te
i
Straße
es
ku
Mädchen
ypsilon
we
Bäcker
be
Freund
em
pe
e
jot
Öl
Stein
König
Sport
Licht
System
Sache
Fach
neu
ich
möchten
Sprache
Vater
Liebe
Fuß
Rauch
Dach
Tag
Bach
echt
auch
Mönch
Buch
noch
Fuchs
Woche
Nacht
lang
acht
grün
Ja
Küche
Hexe
nein
Kirche
Milch
Käse
durch
Deutsch
sechsundsechzig
eins
dreißig
einundzwanzig
einundvierzig
sechs
fünfzehn
dreiundvierzig
zwanzig
neunundsiebzig
null
sieben
neunzehn
achtundsechzig
einundfünfzig
fünfzig
drei
dreiunddreißig
achtundachtzig
achtzig
einundsiebzig
einundsechzig
siebenunddreißig
dreiundneunzig
zweihundertfünfzig
sechsundachtzig
einundneunzig
achtzehn
zehn
dreihundertfünfundvierzig
sechshundertachtundsiebzig
dreiundachtzig
vierzehn
zwölf
zweihundertvierunddreißig
sechzehn
dreiundzwanzig
vier
dreiundfünfzig
zweiundzwanzig
fünfundfünfzig
neunzig
zwei
dreizehn
achtundsiebzig
einhundert
fünf
neun
elf
siebzehn
Bis bald
Willkommen
Wie bitte?
Guten Tag
Freut mich
Hilfe!
Bitte
Vielen Dank
Bis morgen
Hallo
Es tut mir leid
Vielleicht
Ich komme aus Algerien
Entschuldigung
Kein Problem
Wie geht es Ihnen?
Gute Nacht
Gut, danke
Und dir?
Guten Morgen
Wie heißt du?
Guten Appetit
Wie viel kostet das?
Ich spreche ein bisschen Deutsch
Wo ist die Toilette?
Wo wohnst du?
Tschüss
Noch einmal, bitte
Ich heiße …
Ich weiß nicht
Wie geht’s?
Auf Wiedersehen
Nein
Ich verstehe nicht
Woher kommst du?
Sprichst du Englisch?
Langsamer, bitte
fünf nach zehn
fünf nach halb elf
fünf vor neun
halb acht
Viertel vor zwölf
Viertel nach fünf
Viertel vor acht
Mittwoch
Viertel vor vier
zehn nach zwei
Samstag
Donnerstag
fünf nach halb zwei
zehn nach zehn
zehn vor fünf
fünf vor zwei
fünf Uhr
fünf vor elf
zehn nach acht
fünf nach acht
halb elf
zehn nach eins
zehn vor zehn
zwanzig vor zwei
Viertel nach vier
zehn nach elf
Dienstag
zwanzig vor zehn
zwanzig nach vier
Viertel vor elf
zwei Uhr
der Mund
die Pizza
die Kuh
der Stuhl
das Handy
die Brille
die Hand
das Haus
das Auge
der Bleistift
der Schuh
das Fahrrad
das Schaf
der Vogel
weiß
der Schlüssel
die Orange
die Banane
der Regenschirm
braun
das Flugzeug
die Biene
das Ohr
das Buch
blau
das Ei
der Apfel
der Rucksack
der Salat
die Zitrone
der Kuchen
der Bus
der Fisch
der Tee
die Schlange
rot
die Erdbeere
das Fenster
der Bär
der Wecker
das Brot
das Huhn
der Hund
die Tomate
der Löwe
der Käse
die Blume
die Kartoffel
der Zug
die Katze
das Pferd
die Tür
das Bett
der Kaffee
Übung
Brüder
a
ä
ge
Zeit
fau
ix
ef
Gespräch
Kalb
Häuser
Quelle
sprechen
Sonne
Bücher
Tuch
welche
schön
Wasser
Koch
Hund
machen
nicht
Pferd
sechzig
fünfundneunzig
vierunddreißig
zweiundfünfzig
siebenhundertneunundachtzig
achthundertzwölf
achtundvierzig
einhundertdreiundzwanzig
neunundzwanzig
neunhundertneunundneunzig
neunhundertfünf
vierzig
sechsundneunzig
vierhundertsechsundfünfzig
zweiundvierzig
achtunddreißig
neunundneunzig
sechsundvierzig
fünfundsechzig
siebzig
fünfundzwanzig
sechsunddreißig
neununddreißig
neunundachtzig
vierundneunzig
fünfhundertsiebenundsechzig
zweiunddreißig
zweiundachtzig
siebenundsiebzig
vierundfünfzig
zweiundsechzig
vierundachtzig
siebenundfünfzig
vierundsechzig
Guten Abend
Danke
Viertel vor fünf
halb sechs
fünf vor halb zwölf
elf Uhr
Viertel vor zwei
zwanzig vor fünf
fünf vor zwölf
halb zehn
Montag
fünf vor zehn
fünf nach halb drei
sieben Uhr
zehn nach fünf
zehn nach drei
Sonntag
zehn vor zwei
Freitag
fünf vor halb zwei
zwanzig vor drei
zwanzig vor sechs
die Schokolade
der Computer
orange
das Auto
rosa
der Fuß
die Nase
der Reis
der Elefant
der Schnee
der Baum
gelb
das Herz
die Sonne
das Schwein
grau
schwarz
der Stern
der Mond
die Milch
die Ente
das Feuer
die Maus
der Regen
der Berg
Du arbeitest
Er fährt
Du liest
Er wohnt
Du isst
Ich spiele
Er liest
Ich mache
Er geht
Er sieht
Wir sprechen
Wir spielen
Wir lernen
Ich lese
Du heißt
Wir kommen
Ich arbeite
Ich schlafe
Ich sehe
Du machst
Er trinkt
Ich spreche
Du sprichst
Wir machen
Wir fahren
Du gehst
Wir trinken
Du lernst
Ich trinke
Du siehst
Er schläft
Du fährst
Du wohnst
Ich gehe
Er spricht
Wir lesen
Wir heißen
Er isst
Ich esse
Ich fahre
Wir arbeiten
Wir sind zu Hause.
Ihr seid zu Hause.
Die Kinder sind zu Hause.
Er ist zu Hause.
der Bruder
der Tag
das Kind
die Woche
der Tisch
die Frau
das Zimmer
die Mutter
die Familie
das Wasser
Du hast Hunger.
Er hat Hunger.
Ihr habt Hunger.
Ich habe Hunger.
Wir haben Hunger.
Du schläfst
Du kommst
Wir sehen
Ich komme
Wir schlafen
Ich wohne
Ich lerne
Wir essen
Er arbeitet
Er lernt
die Tasche
Er heißt
Er macht
der Mann
Ich heiße
Er kommt
Ich bin zu Hause.
Du bist zu Hause.
Wir wohnen
Die Kinder haben Hunger.
die Stadt
Wir gehen
Du trinkst
Du spielst
die Schule
Er spielt
Du sollst heute kommen.
Er soll heute kommen.
Ich soll heute kommen.
Ich will heute kommen.
Wir dürfen heute kommen.
Wir können heute kommen.
Er muss heute kommen.
Du kannst heute kommen.
Wir müssen heute kommen.
Er kann heute kommen.
Du willst heute kommen.
Ich muss heute kommen.
Er darf heute kommen.
Wir sollen heute kommen.
Ich darf heute kommen.
von der Frau
zu dem Arzt
mit dem Zug
mit dem Bus
bei der Oma
mit der Freundin
von dem Kind
seit dem Jahr
bei dem Arzt
nach dem Essen
aus dem Haus
Plural: der Bruder → die Brüder
Plural: das Kind → die Kinder
Plural: der Student → die Studenten
Plural: die Katze → die Katzen
Plural: das Zimmer → die Zimmer
Plural: der Tag → die Tage
Plural: die Tasche → die Taschen
Plural: die Mutter → die Mütter
Plural: der Apfel → die Äpfel
Plural: das Haus → die Häuser
Plural: der Hund → die Hunde
Plural: die Frau → die Frauen
Plural: der Stuhl → die Stühle
Plural: das Land → die Länder
Plural: der Tisch → die Tische
Ich habe geschrieben.
Ich habe gegessen.
Er hat gestern gearbeitet.
Er hat gestern getroffen.
Er ist gestern gekommen.
Ich habe gesprochen.
Er hat gestern gelesen.
Er hat gestern gemacht.
Ich bin geflogen.
Er hat gestern gegeben.
Ich habe angerufen.
Ich bin aufgestanden.
Ich habe gespielt.
Ich habe eingekauft.
Ich bin gegangen.
Ich habe getrunken.
Er hat gestern geschlafen.
Er hat gestern vergessen.
Ich habe vergessen.
Ich habe gekauft.
Er hat gestern getrunken.
Er hat gestern eingekauft.
Ich habe gesehen.
Er hat gestern genommen.
Er ist gestern gelaufen.
Er ist gestern gegangen.
Er hat gestern bezahlt.
Ich habe bezahlt.
Er hat gestern gelernt.
Ich habe gelernt.
Ich habe genommen.
Er hat gestern gegessen.
Ich habe gemacht.
Er hat gestern gesprochen.
Er hat gestern gekauft.
mit dem Kind
von dem Mann
Ich habe geschlafen.
Ich habe besucht.
Er hat gestern angerufen.
Ich habe geholfen.
Er hat gestern besucht.
Ich habe gelesen.
Ich habe gegeben.
Ich bin gekommen.
Ich habe gearbeitet.
Plural: der Mann → die Männer
Er ist gestern aufgestanden.
zu der Schule
Er will heute kommen.
Er hat gestern geholfen.
Plural: das Auto → die Autos
Du musst heute kommen.
Er hat gestern gesehen.
nach der Schule
Er hat gestern gefunden.
Plural: das Handy → die Handys
Er ist gestern geblieben.
Plural: das Buch → die Bücher
Ich kann heute kommen.
Wir wollen heute kommen.
aus der Stadt
Plural: die Stadt → die Städte
Er hat gestern geschrieben.
Ich bin gelaufen.
Ich bin gefahren.
Ich habe gefunden.
Er hat gestern gespielt.
Ich bin geblieben.
Du darfst heute kommen.
Ich habe getroffen.
Er ist gestern geflogen.
Er ist gestern gefahren.
er/sie ging
er/sie schlief
er/sie las
er/sie war
er/sie fuhr
er/sie dachte
er/sie machte
er/sie aß
er/sie musste
er/sie trank
er/sie fand
er/sie half
er/sie brachte
er/sie blieb
er/sie lernte
er/sie lief
er/sie kam
er/sie sah
er/sie wollte
er/sie sprach
er/sie spielte
teilnehmen an
abhängen von
denken an
Angst haben vor
sprechen über
fragen nach
sich entschuldigen für
träumen von
sich kümmern um
sich interessieren für
ein alter Mann
ein großes Haus
der gute Mann
Als ich ein Kind war, wohnte ich in Algier.
Ich gehe nach Hause, weil ich müde bin.
Ich weiß nicht, ob er kommt.
Er lernt, damit er die Prüfung besteht.
Wenn ich nach Hause komme, koche ich.
Das ist die Frau, die im Café arbeitet.
Das ist das Kind, dem ich helfe.
Das ist der Mann, den ich kenne.
Das ist die Frau, der ich helfe.
Der Mann, dessen Auto kaputt ist, ruft die Werkstatt an.
eine schöne Stadt
glauben an
sich freuen über
Obwohl es regnet, gehen wir spazieren.
er/sie wusste
sich beschweren über
mit dem neuen Auto
er/sie konnte
die kleinen Kinder
Das Buch, das ich lese, ist spannend.
er/sie schrieb
sich verlieben in
er/sie gab
er/sie hatte
bestehen aus
sich erinnern an
warten auf
er/sie arbeitete
er/sie nahm
sich freuen auf
Ich weiß, dass er krank ist.
ich wäre
ich käme
ich nähme
ich wüsste
ich brächte
ich führe
ich ginge
ich gäbe
ich sähe
ich müsste
ich hätte
Das Problem muss sofort gelöst werden.
Hier wird nicht geraucht.
Die Briefe wurden gestern geschrieben.
Das Auto ist repariert worden.
Der Kuchen wurde gebacken.
trotz des Regens
während der Reise
statt des Kaffees
aufgrund des Lärms
ich bliebe
wegen der Krankheit
wegen des Wetters
ich dürfte
Das Haus wird gerade gebaut.
während des Sommers
ich fände
trotz der Kinder
ich könnte
Der Minister erklärte, er werde zurücktreten.
Er sagt, er sei krank.
Funktionsverbgefüge: eine Frage stellen
Funktionsverbgefüge: Einfluss nehmen
Funktionsverbgefüge: zur Verfügung stellen
Funktionsverbgefüge: eine Entscheidung treffen
Funktionsverbgefüge: in Kauf nehmen
Funktionsverbgefüge: Stellung nehmen
Funktionsverbgefüge: in Betracht ziehen
Funktionsverbgefüge: zur Sprache bringen
Sie sagte, sie habe keine Zeit.
Funktionsverbgefüge: Kritik üben
Sie behauptet, er sei gestern hier gewesen.
Funktionsverbgefüge: Rücksicht nehmen
Wenn ich mehr Zeit gehabt hätte, wäre ich mitgekommen.
Hätte ich das gewusst, hätte ich anders gehandelt.
Er tat so, als hätte er nichts gehört.
Wäre er früher gekommen, hätte er den Zug erreicht.""".strip().split("\n")

def fnv(s):  # نفس دالة التجزئة في index.html
    h = 0x811C9DC5
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return format(h, "08x")

H = {"Authorization": "Bearer " + SERVICE_KEY, "apikey": SERVICE_KEY}
r = requests.post(SUPABASE_URL + "/storage/v1/bucket", headers={**H, "Content-Type": "application/json"},
                  json={"id": "audio", "name": "audio", "public": True})
print("bucket:", r.status_code, r.text[:80])

def upload(name, data):
    return requests.post(SUPABASE_URL + "/storage/v1/object/audio/" + name,
                         headers={**H, "Content-Type": "audio/mpeg", "x-upsert": "true"}, data=data).status_code

async def one(t, sem, codes):
    name = fnv(t) + ".mp3"; path = "/tmp/" + name
    async with sem:
        await edge_tts.Communicate(t, VOICE, rate="-10%").save(path)
        codes.append(await asyncio.to_thread(upload, name, open(path, "rb").read()))
    os.remove(path)

async def main():
    sem, codes = asyncio.Semaphore(4), []
    await asyncio.gather(*(one(t, sem, codes) for t in TEXTS))
    print("رُفع:", sum(c in (200, 201) for c in codes), "من", len(TEXTS))

asyncio.run(main())
