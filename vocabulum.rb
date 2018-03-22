#! /usr/bin/env ruby

class Verbum
  attr_reader :uebersetzungen
  attr_accessor :treffsicherheit

  def initialize(id, uebersetzungen, treffsicherheit=0)
    @id = id
    @uebersetzungen = uebersetzungen
    @treffsicherheit = treffsicherheit
  end
end

class Corpus
  attr_reader :sprachen

  def initialize(vondatei)
    @lima = Lima.new(vondatei)
    @alleworte = {}
    @sprachen = @lima.sprachen

    @lima.dateiinhalt.each do |elementi|
      @alleworte[elementi[0].to_i] = Verbum.new(elementi[0].to_i, elementi[1..-2], elementi[-1].to_i)
    end
  end

  def wortwolke(ausgangssprachennr, uebersetzungssprachennr, wortanzahl)
    wortanzahl > @alleworte.size ? umfang = @alleworte.size : umfang = wortanzahl
    tsliste = []
    min = 10000000000 #Achtung: spaeter moegliche Fehlerquelle 
    max = 0
    @alleworte.each do |id, verbum|
      min = verbum.treffsicherheit if verbum.treffsicherheit < min
      max = verbum.treffsicherheit if verbum.treffsicherheit > max
      tsliste[verbum.treffsicherheit] ? tsliste[verbum.treffsicherheit] << id : tsliste[verbum.treffsicherheit] = [id]
    end
    # aus der tsliste nun von unten = ganz schwer 20%, aus der Mitte = noch nicht sicher 60% und von oben = sicher 20% nehmen
    # vorerst:
    return @alleworte
  end

  def aktualisiere(verbi)
    verbi.each do |id,verbum|
      @alleworte[id] = verbum
    end
    @lima.speichere_neue_daten(@alleworte)
  end

end

class Lima
  attr_reader :sprachen, :dateiinhalt

  def initialize(dateiname)
    @dateiname = dateiname
    @sprachen = []
    @dateiinhalt = []

    z = 0
    File.read(@dateiname).split("\n").each do |versus|
      versus.chomp! #Zeilenumbruch entfernen
      if z == 0
        @sprachen = versus.split(";")[1..-2]
      else
        @dateiinhalt << versus.split(";")
      end
      z += 1
    end
  end

  # def get_languages
  #   sprachenzeile = File.open(self.dateiname, "r").split("\n").first
  #   return sprachenzeile.split(";")[1..-1] # lässt das erste, leere Element weg
  # end

  def speichere_neue_daten(verbi)
    system("cp #{@dateiname} #{@dateiname}.bak")
    csv = File.open(@dateiname, "w") 
    csv.write(";" + @sprachen.join(";") + ";Treffsicherheit\n")
    verbi.each do |id,verbum|
      csv.write(id.to_s + ";" + verbum.uebersetzungen.join(";") + ";" + verbum.treffsicherheit.to_s + "\n")
    end
  end
end

class Trainer
  attr_reader :wortwolke

  def initialize(wortwolke,ausgangssprachennr,uebersetzungssprachennr,mixed=false)
    @wortwolke = wortwolke
    @ausgangssprachennr = ausgangssprachennr
    @uebersetzungssprachennr = uebersetzungssprachennr
    @mixed = mixed

  end

  def training(durchlaeufe)
    treffer = 0
    durchlaeufe.times do
      id = rand(1..@wortwolke.size)
      treffer += aenigma(id)
    end

    return treffer
  end

  def aenigma(id)
    verbum = @wortwolke[id]
    frage = verbum.uebersetzungen[@ausgangssprachennr]
    antwort = verbum.uebersetzungen[@uebersetzungssprachennr]
    system('clear')
    print "Die Übersetzung für #{frage} lautet: "
    versuch = gets
    treffer = 0
    if versuch.chomp! == antwort
      puts "Jawoll"
      verbum.treffsicherheit += 1
      sleep 1
      return 1
    else
      puts "Nope :-( Die Antwort lautet ::::  #{antwort}  ::::"
      verbum.treffsicherheit -= 1 if verbum.treffsicherheit > 0
      sleep 2
      return 0
    end
  end

end

puts "Dann wollen wir mal..."
corpus = Corpus.new("verbi.csv")
puts "Ich habe folgende Sprachen zur Auswahl:"
puts corpus.sprachen.join(",")
print "Welche Sprache soll Deine Ausgangssprache sein [de] : "
ausgangssprache = gets
ausgangssprache.chomp!
if ausgangssprache == ""
  ausgangssprachennr = corpus.sprachen.index("de")
else
  while not corpus.sprachen.include?(ausgangssprache)
    puts "#{ausgangssprache} habe ich nicht im Angebot. Bitte wähle zwischen"
    puts corpus.sprachen.join(",")
    print "Welche Sprache soll Deine Ausgangssprache sein [de] : "
    ausgangssprache = gets
    ausgangssprache.chomp!
  end
  ausgangssprachennr = corpus.sprachen.index(ausgangssprache)
end

print "OK, und welche der o.g. Sprachen möchtest Du üben? : "

uebersetzungssprache = gets
uebersetzungssprache.chomp!
while not corpus.sprachen.include?(uebersetzungssprache)
  puts "#{uebersetzungssprache} habe ich nicht im Angebot. Bitte wähle zwischen"
  puts corpus.sprachen.join(",")
  print "Welche Sprache möchtest Du lernen? : "
  uebersetzungssprache = gets
  uebersetzungssprache.chomp!
end
uebersetzungssprachennr = corpus.sprachen.index(uebersetzungssprache)

zu_trainierende_worte = corpus.wortwolke(ausgangssprachennr, uebersetzungssprachennr, 5)
trainer = Trainer.new(zu_trainierende_worte, ausgangssprachennr, uebersetzungssprachennr)
treffer = trainer.training(3)
corpus.aktualisiere(trainer.wortwolke)
system('clear')
puts "Du hattest #{treffer} Treffer."