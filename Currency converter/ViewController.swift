//
//  ViewController.swift
//  Currency converter
//
//  Created by Apple on 9/15/17.
//  Copyright © 2017 Mari. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currencies = [String]()
    var flag: Bool = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.label.text = "Тут будет курс"
        
        
        self.pickerFrom.dataSource = self
        self.pickerTo.dataSource = self
        
        self.pickerFrom.delegate = self
        self.pickerTo.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestCurrentAvailableCurrencies()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === pickerTo {
            return self.currenciesExceptBase().count
        }
        if !currencies.isEmpty {
            return currencies.count
        } else {
            self.requestCurrentAvailableCurrencies()
            return currencies.count
        }
    }
    
    //MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickerTo {
            return self.currenciesExceptBase()[row]
        }
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickerFrom {
            self.pickerTo.reloadAllComponents()
        }
        
        self.requestCurrentAvailableCurrencies()
        self.requestCurrentCurrencyRate()
    }
    
    //MARK: - Network
    //MARK: - Request currency rates
    
    func requestCurrencyRates(baseCurrency: String, parseHandler : @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        
            dataTask.resume()
        
    }
    
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completion: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) { [weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            completion(string)
        }
    }
    
    func requestCurrentCurrencyRate() {
        self.activityIndicator.startAnimating()
        self.label.text = " "
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        if !currencies.isEmpty {
            let baseCurrency = currencies[baseCurrencyIndex]
            let toCurrency = currenciesExceptBase()[toCurrencyIndex]
            
            self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) { [weak self] (value) in
                DispatchQueue.main.async(execute: {
                    if let strongSelf = self {
                        if value == "The Internet connection appears to be offline." {
                            strongSelf.label.text = "Offline"
                        } else {
                            strongSelf.label.text = value
                        }
                        strongSelf.activityIndicator.stopAnimating()
                    }
                })
            }
        }
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value : String = " "
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            self.flag = true
            if let parsedJSON = json {
//                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    if let rate = rates[toCurrency] {
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else {
                    if !self.flag {
                        value = "No \"rates\" field found"
                    }
                }
            } else {
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        
        return value
    }
    
    //MARK: - Request list of available currencies
    
    func requestCurrentAvailableCurrencies() {
        self.retrieveAvailableCurrencies() { [weak self] (value) in
            DispatchQueue.main.async(execute: {
                if let strongSelf = self {
                    
                    if value != "The Internet connection appears to be offline." {
                        UIView.transition(with: strongSelf.view, duration: 0.5, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                            strongSelf.label.text = value
                        }, completion: nil)

                        strongSelf.requestCurrentCurrencyRate()
                        strongSelf.pickerTo.reloadAllComponents()
                        strongSelf.pickerFrom.reloadAllComponents()
                    } else {
                        UIView.transition(with: strongSelf.view, duration: 0.5, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                            strongSelf.label.text = "Offline"
                        }, completion: nil)
                        strongSelf.pickerTo.reloadAllComponents()
                        strongSelf.pickerFrom.reloadAllComponents()
                    }

                }
            })
        }
    }
    
    
    func retrieveAvailableCurrencies(completion: @escaping (String) -> Void) {
        self.requestAvailableCurrencies() { [weak self] (data, error) in
            var string = "No currencies are available!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseAvailableCurrenciesResponse(data: data)
                }
            }
            
            completion(string)
        }
    }
    
    func requestAvailableCurrencies(parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest")!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        
        dataTask.resume()
    }
    
    func parseAvailableCurrenciesResponse(data: Data?) -> String {
        var value : String = ""
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double> {
                    for key in rates.keys {
                        if !currencies.contains(key) {
                            currencies.append(key)
                        }
                    }
                } else {
                    value = "No \"rates\" field found"
                }
                if let base = parsedJSON["base"] as? String {
                    if !currencies.contains(base) {
                        currencies.append(base)
                    }
                } else {
                    value = "No \"base\" field found"
                }
                
            } else {
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        return value
    }
    
    
    //MARK: - Helper
    
    func currenciesExceptBase() -> [String] {
        var currenciesExceptBase = currencies
        if !currenciesExceptBase.isEmpty {
            currenciesExceptBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        }
        return currenciesExceptBase
    }

    
}

