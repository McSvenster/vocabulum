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
        @linguae = versus.split(";")[1..-2]
      else
        id = versus.split(";")[0].to_i
        verbi = versus.split(";")[1..-2]
        treffsicherheiten = versus.split(";")[-1]
        trefferliste = {}
        (1..@linguae.size).each do |lnr|
          trefferliste[lnr] = 0
        end
        c = 0
        treffsicherheiten.split(":").each do |tl|
          trefferliste[c] = tl.split(",")
          c += 1  
        end
        @vocabuli << Vocabulum.new(id,@linguae,verbi,trefferliste)
      end
      z += 1
    end
  end

  def speichere_neue_daten(vocabuli)
    system("cp #{@dateiname} #{@dateiname}.bak")
    csv = File.open(@dateiname, "w") 
    csv.write(";" + @linguae.join(";") + ";Treffsicherheit\n")
    vocabuli.each do |id,vocabulum|
      csv.write(id.to_s + ";" + vocabulum.verbi.join(";") + ";" + vocabulum.schreibe_trefferliste + "\n")
    end
    csv.close
  end
end


class Vocabulum
  attr_reader :id, :verbi
  # attr_accessor :treffsicherheiten

  def initialize(id, linguae, verbi, trefferliste)
    @id = id
    @linguae = linguae
    @verbi = verbi
    @trefferliste = trefferliste
  end

  def zeige_treffer(ausgangssprachennr,uebersetzungssprachennr)
    treffer = @trefferliste[ausgangssprachennr]
    return treffer[uebersetzungssprachennr].to_i
  end

  def schreibe_treffer(ausgangssprachennr,uebersetzungssprachennr,treffer)
    @trefferliste[ausgangssprachennr][uebersetzungssprachennr] = treffer
  end

  def schreibe_trefferliste()
    tla = []
    @trefferliste.each do |tl|
      tla << tl.join(",")
    end
    return tla.join(":")
  end

end


class Corpus
  attr_reader :linguae
  attr_accessor :vocabuli

  def initialize(vocabuli,linguae)
    @vocabuli = {}
    vocabuli.each do |v|
      @vocabuli[v.id] = v
    end
    @linguae = linguae

    # @lima.dateiinhalt.each do |elementi|
    #   @alleworte[elementi[0].to_i] = Verbum.new(elementi[0].to_i, elementi[1..-2], elementi[-1].to_i)
    # end
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
    zu_trainierende_worte = []
    @vocabuli.each do |id,v|
      zu_trainierende_worte << v
    end
    uebungscorpus = Corpus.new(zu_trainierende_worte, @linguae)
    return uebungscorpus
  end

  def aktualisiere(uebungscorpus)
    uebungscorpus.vocabuli.each do |id,vocabulum|
      @vocabuli[id] = vocabulum
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
      id = rand(1..@uebungscorpus.vocabuli.size)
      aenigma(id)
    end

    return @heute_korrekt
  end

  def aenigma(id)
    verbum = @uebungscorpus.vocabuli[id]
    frage = verbum.verbi[@ausgangssprachennr]
    antwort = verbum.verbi[@uebersetzungssprachennr]
    system('clear')
    print "Die Übersetzung für #{frage} lautet: "
    versuch = gets
    treffer = verbum.zeige_treffer(@ausgangssprachennr,@uebersetzungssprachennr)
    if versuch.chomp! == antwort
      puts "Jawoll"
      treffer += 1
      @heute_korrekt += 1
      sleep 1
      return 1
    else
      puts "Nope :-( Die Antwort lautet ::::  #{antwort}  ::::"
      treffer -= 1 if treffer > 0
      sleep 2
      return 0
    end
    verbum.schreibe_treffer(@ausgangssprachennr,@uebersetzungssprachennr,treffer)
  end

end

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
  while not woertchen.include?(":")
    puts "Bitte das deutsche Wort und die Übersetzung durch einen Doppelpunkt getrennt eingeben."
    puts "deutsch:#{uebersetzungssprache}"
    woertchen = gets
  end
  woertchen.chomp!
  wort,uebersetzung = woertchen.split(":")
  wort = wort.split()
  uebersetzung = uebersetzung.split()
  wortliste[wort] = uebersetzung
end

## neue Vokabeln dem Corpus hinzufuegen

uebungscorpus = corpus.extrahiere_uebungscorpus(ausgangssprachennr, uebersetzungssprachennr, 5)
trainer = Trainer.new(uebungscorpus, ausgangssprachennr, uebersetzungssprachennr)
treffer = trainer.training(3)
corpus.aktualisiere(trainer.uebungscorpus)
uebungsdatei.speichere_neue_daten(corpus.vocabuli)
system('clear')
puts "Du hattest #{treffer} Treffer."