//
//  CurrentPriceVC.swift
//  Bitcoin
//
//  Created by Behzad Karimi on 15.01.20.
//  Copyright © 2020 Behzad Karimi. All rights reserved.
//

import UIKit

class CurrentPriceVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var btcToUsd: UILabel!
    @IBOutlet weak var btcToGbp: UILabel!
    @IBOutlet weak var btcToEur: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var countryPickerView: UIPickerView!
    @IBOutlet weak var pickedCountry: UILabel!
    @IBOutlet weak var pickedCountryRate: UILabel!
    
    var supportedCountries: [Country] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        requestStandardRates()
        requestSupportedCountries()
        Timer.scheduledTimer(timeInterval: 60, target: self, selector: Selector(("requestStandardRates")), userInfo: nil, repeats: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.supportedCountries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let country = supportedCountries[row]
        let countryString = country.currency + " - " + country.country
        return countryString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let country = supportedCountries[row]
        self.requestCountryRate(countryCode: country.currency)
        let countryString = country.currency + " - " + country.country
        self.pickedCountry.text = countryString
    }
    
    fileprivate func requestCountryRate(countryCode: String) {
        let buildURL = "https://api.coindesk.com/v1/bpi/currentprice/<CODE>.json"
        let urlWithCountryCode = buildURL.replacingOccurrences(of: "<CODE>", with: countryCode)
        let url = URL(string: urlWithCountryCode)!
                
        let urlSession = URLSession.shared
        debugPrint("Start request to ", url)
        
        let task = urlSession.dataTask(with: url) { (data, response, error) in
            
            guard let dataResponse = data else {
                debugPrint("Error during loading", error ?? "Unknown error")
                return
            }
            
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String: Any] {
                    
                    debugPrint("Extracting data from response")
                
                    var ratesDictionary = jsonDictionary["bpi"] as? [String: Any]
                    ratesDictionary?.removeValue(forKey: "USD")
                    
                    let pickedCountry = ratesDictionary?.popFirst()
                    let countryAttributes = pickedCountry?.value as? [String: Any]
                    let countryRate = countryAttributes?["rate"] as? String
                    
                    OperationQueue.main.addOperation {
                        self.pickedCountryRate.text = countryRate
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    
     @objc fileprivate func requestStandardRates() {
        let url = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!
        
        let urlSession = URLSession.shared
        debugPrint("Start request to ", url)
        
        let task = urlSession.dataTask(with: url) { (data, response, error) in
            
            guard let dataResponse = data else {
                debugPrint("Error during loading", error ?? "Unknown error")
                return
            }
            
            do{
                let decoder = JSONDecoder()
                let actualExchangeRate = try decoder.decode(ExchangeRate.self, from: dataResponse)
                let usd = actualExchangeRate.bpi.USD.rate
                let gbp = actualExchangeRate.bpi.GBP.rate
                let eur = actualExchangeRate.bpi.EUR.rate
                let lastTimeUpdated = actualExchangeRate.time.updated
                
                DispatchQueue.main.async {
                    self.btcToUsd.text = usd + " $"
                    self.btcToGbp.text = gbp + " £"
                    self.btcToEur.text = eur + " €"
                    self.date.text = lastTimeUpdated
                }
            } catch { print(error) }
        }
        task.resume()
    }
    
    
    func requestSupportedCountries() {
        let urlCountries = URL(string: "https://api.coindesk.com/v1/bpi/supported-currencies.json")!
        
        let urlSessionCountries = URLSession.shared
        debugPrint("Start request to ", urlCountries)
        
        let taskCountries = urlSessionCountries.dataTask(with: urlCountries) { (data, response, error) in
            
            guard let dataResponse = data else {
                debugPrint("Error during loading", error ?? "Unknown error")
                return
            }
            
            self.supportedCountries = try! JSONDecoder().decode([Country].self, from: dataResponse)
            let country = self.supportedCountries[0]
            self.requestCountryRate(countryCode: country.currency)
            let countryString = country.currency + " - " + country.country
            
            OperationQueue.main.addOperation {
                self.countryPickerView.reloadAllComponents()
                self.pickedCountry.text = countryString
            }
        }
        taskCountries.resume()
    }
}
