#! /usr/bin/env ruby

class Lima
  attr_reader :linguae, :vocabuli

  def initialize(dateiname)
    @dateiname = dateiname
    @linguae = []
    @vocabuli = []

    z = 0
    File.read(@dateiname).split("\n").each do |versus|
      versus.chomp! #Zeilenumbruch entfernen
      if z == 0
        @linguae = versus.split(";")[0..-2]
      else
        verbi = versus.split(";")[0..-2]
        treffsicherheiten = versus.split(";")[-1]
        trefferliste = treffsicherheiten.split(",")
        @vocabuli << Vocabulum.new(@linguae,verbi,trefferliste)
      end
      z += 1
    end
  end

  def speichere_neue_daten(corpus)
    system("cp #{@dateiname} #{@dateiname}.bak")
    csv = File.open(@dateiname, "w") 
    csv.write(corpus.linguae.join(";") + ";Treffsicherheit\n")
    corpus.vocabuli.each do |vocabulum|
      csv.write(vocabulum.verbi.join(";") + ";" + vocabulum.schreibe_trefferliste + "\n")
    end
    csv.close
  end
end


class Vocabulum
  attr_accessor :linguae, :verbi, :trefferliste

  def initialize(linguae, verbi, trefferliste)
    @linguae = linguae
    @verbi = verbi
    @trefferliste = trefferliste
  end

  def zeige_treffer(uebersetzungssprachennr)
    return @trefferliste[uebersetzungssprachennr-1].to_i
  end

  def schreibe_treffer(uebersetzungssprachennr,treffer)
    @trefferliste[uebersetzungssprachennr-1] = treffer
  end

  def schreibe_trefferliste()
    return @trefferliste.join(",")
  end

end


class Corpus
  attr_reader :linguae
  attr_accessor :vocabuli

  def initialize(vocabuli,linguae)
    @vocabuli = vocabuli
    @linguae = linguae
  end

  def extrahiere_uebungscorpus(ausgangssprachennr, uebersetzungssprachennr, wortanzahl=5)
    # wortanzahl > @vocabuli.size ? umfang = @vocabuli.size : umfang = wortanzahl
    # tsliste = []
    # min = 10000000000 #Achtung: spaeter moegliche Fehlerquelle 
    # max = 0
    # @vocabuli.each do |id, verbum|
    #   min = verbum.treffsicherheit if verbum.treffsicherheit < min
    #   max = verbum.treffsicherheit if verbum.treffsicherheit > max
    #   tsliste[verbum.treffsicherheit] ? tsliste[verbum.treffsicherheit] << id : tsliste[verbum.treffsicherheit] = [id]
    # end
    # aus der tsliste nun von unten = ganz schwer 20%, aus der Mitte = noch nicht sicher 60% und von oben = sicher 20% nehmen
    # vorerst:
    zu_trainierende_worte = @vocabuli
    uebungscorpus = Corpus.new(zu_trainierende_worte, @linguae)
    return uebungscorpus
  end

  def ergaenze(vocabulum)
    if @vocabuli.any? { |v| v.verbi.include?(vocabulum.verbi.first) }
      corp_voc = @vocabuli.find { |v| v.verbi.include?(vocabulum.verbi.first) }
    else
      verbi = []
      treffer = []
      (0...@linguae.size).each do |c|
        verbi[c] = ""
        treffer[c] = 0
      end
      treffer.shift
      corp_voc = Vocabulum.new(@linguae,verbi,treffer)
      @vocabuli << corp_voc
    end

    @linguae.each do |l|
      if vocabulum.linguae.include?(l)
        corp_voc.verbi[@linguae.index(l)] = vocabulum.verbi[vocabulum.linguae.index(l)]
        unless l == "de"
          corp_voc.trefferliste[@linguae.index(l)-1] = vocabulum.trefferliste[vocabulum.linguae.index(l)-1]
        end
      end
    end
    
  end

end


class Trainer
  attr_reader :uebungscorpus

  def initialize(uebungscorpus,ausgangssprachennr,uebersetzungssprachennr,mixed=false)
    @uebungscorpus = uebungscorpus
    @ausgangssprachennr = ausgangssprachennr
    @uebersetzungssprachennr = uebersetzungssprachennr
    @mixed = mixed
    @heute_korrekt = 0
  end

  def training(durchlaeufe)
    durchlaeufe.times do
      nr = rand(0...@uebungscorpus.vocabuli.size)
      while @uebungscorpus.vocabuli[nr].verbi[@uebersetzungssprachennr] == ""
        nr = rand(0...@uebungscorpus.vocabuli.size)
      end
      aenigma(nr)
    end

    return @heute_korrekt
  end

  def aenigma(nr)
    verbum = @uebungscorpus.vocabuli[nr]
    frage = verbum.verbi[@ausgangssprachennr]
    antwort = verbum.verbi[@uebersetzungssprachennr]
    system('clear')
    print "Die Übersetzung für #{frage} lautet: "
    versuch = gets
    treffer = verbum.zeige_treffer(@uebersetzungssprachennr)
    if versuch.chomp! == antwort
      puts "Jawoll"
      treffer += 1
      @heute_korrekt += 1
      sleep 1
    else
      puts "Nope :-( Die Antwort lautet ::::  #{antwort}  ::::"
      treffer -= 1 if treffer > 0
      sleep 4
    end
    verbum.schreibe_treffer(@uebersetzungssprachennr,treffer)
  end

end

system('clear')
puts "Dann wollen wir mal..."

## Daten einlesen
uebungsdatei = Lima.new("verbi.csv")

## gesamten Corpus bauen
corpus = Corpus.new(uebungsdatei.vocabuli, uebungsdatei.linguae)

## Uebungssprache festlegen
puts "Ich habe folgende Sprachen zur Auswahl:"
puts corpus.linguae.join(",")
# print "Welche Sprache soll Deine Ausgangssprache sein [de] : "
# ausgangssprache = gets
# ausgangssprache.chomp!
# if ausgangssprache == ""
#   ausgangssprachennr = corpus.linguae.index("de")
# else
#   while not corpus.linguae.include?(ausgangssprache)
#     puts "#{ausgangssprache} habe ich nicht im Angebot. Bitte wähle zwischen"
#     puts corpus.linguae.join(",")
#     print "Welche Sprache soll Deine Ausgangssprache sein [de] : "
#     ausgangssprache = gets
#     ausgangssprache.chomp!
#   end
#   ausgangssprachennr = corpus.linguae.index(ausgangssprache)
# end
ausgangssprachennr = corpus.linguae.index("de")

print "Welche der o.g. Sprachen möchtest Du üben? : "

uebersetzungssprache = gets
uebersetzungssprache.chomp!
while not corpus.linguae.include?(uebersetzungssprache)
  puts "#{uebersetzungssprache} habe ich nicht im Angebot. Bitte wähle zwischen"
  puts corpus.linguae.join(",")
  print "Welche Sprache möchtest Du lernen? : "
  uebersetzungssprache = gets
  uebersetzungssprache.chomp!
end
uebersetzungssprachennr = corpus.linguae.index(uebersetzungssprache)

## 3 neue Vokabeln eingeben
puts "Im ersten Schritt erfassen wir drei neue Vokabeln."
wortliste = {}
while wortliste.size < 3
  puts "#{wortliste.size + 1}. Wort bitte folgendermassen eingeben:"
  puts "deutsch:#{uebersetzungssprache}"
  woertchen = gets
  while not woertchen.include?(":") && woertchen.chomp.split(":").size == 2
    puts "Bitte das deutsche Wort und die Übersetzung durch einen Doppelpunkt getrennt eingeben."
    puts "deutsch:#{uebersetzungssprache}"
    woertchen = gets
  end
  woertchen.chomp!
  wort,uebersetzung = woertchen.split(":")
  wort = wort.strip()
  uebersetzung = uebersetzung.strip()
  wortliste[wort] = uebersetzung
end

## neue Vokabeln dem Corpus hinzufuegen
wortliste.each do |w,u|
  v = Vocabulum.new(["de",uebersetzungssprache], [w,u], 0)
  corpus.ergaenze(v)
end


uebungscorpus = corpus.extrahiere_uebungscorpus(ausgangssprachennr, uebersetzungssprachennr, 5)
trainer = Trainer.new(uebungscorpus, ausgangssprachennr, uebersetzungssprachennr)
treffer = trainer.training(10)
uebungsdatei.speichere_neue_daten(corpus)
system('clear')
puts "Du hattest #{treffer} Treffer."