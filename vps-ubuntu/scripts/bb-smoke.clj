#!/usr/bin/env bb
(let [result (+ 19 23)]
  (assert (= 42 result) (str "unexpected arithmetic result: " result))
  (println "Babashka smoke OK" result))
