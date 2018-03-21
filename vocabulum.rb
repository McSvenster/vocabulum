#! /usr/bin/env ruby

class Verbum
  def initialize(id, uebersetzungen, treffsicherheit)
    @id = id
    @uebersetzungen = uebersetzungen
    @treffsicherheit = treffsicherheit
  end
end

class Corpus
  def initialize(vondatei)
    @lima = Lima.new(vondatei)
    @wortwolke = []
    @sprachen = []
  end

  def wortwolke_bilden()  
    @sprachen = @lima.sprachen

    @lima.dateiinhalt.each do |elementi|
      @wortwolke << verbum.new(elementi[0], elementi[1..-2], elementi[-1])
    end

  end
end

class Lima
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

  def get_languages
    sprachenzeile = File.open(self.dateiname, "r").split("\n").first
    return sprachenzeile.split(";")[1..-1] # lässt das erste, leere Element weg
  end

  def write_csv
    
  end
end