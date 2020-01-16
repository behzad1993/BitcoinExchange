//
//  LastExchangeRatesTableVC.swift
//  Bitcoin
//
//  Created by Behzad Karimi on 15.01.20.
//  Copyright © 2020 Behzad Karimi. All rights reserved.
//

import UIKit

class LastExchangeRatesTableVC: UITableViewController {

    let numberOfDaysToGet = 14
    var historicalData: HistoricalExchangeRate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestHistoricalData()
    }

        // MARK: - Table view data source

        override func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.numberOfDaysToGet
        }

        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ExchangeRateCell", for: indexPath)
            
            if var exchangeRatesArray = self.historicalData?.exchangeRate {
                exchangeRatesArray.sort{ ($0[0]) < ($1[0]) }
                let exchangeRateArray = exchangeRatesArray[indexPath.row]
                let date = exchangeRateArray[0]
                let price = exchangeRateArray[1]
                let tableRow: String = date + ":   " + price + " $"
                cell.textLabel?.text = tableRow
            }
            return cell
        }
    
    fileprivate func requestHistoricalData() {
        let url = URL(string: "https://api.coindesk.com/v1/bpi/historical/close.json")!
        
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
                    let disclaimer = jsonDictionary["disclaimer"] as? String
                    let time = jsonDictionary["time"] as? [String:Any]
                    let updated = time?["updated"] as? String
                    
                    let ratesDictionary = jsonDictionary["bpi"] as? [String: Any]
                    var sortedRatesDictionary = ratesDictionary?.sorted(by: { $0.key > $1.key })
                    var datesToSafeArray: [[String]] = []
                    //
                    for _ in 0...self.numberOfDaysToGet{
                        if let rateWithDate = sortedRatesDictionary?.removeFirst() {
                            let date = rateWithDate.key
                            if let price = rateWithDate.value as? Double {
                                datesToSafeArray.append([date, String(price)])
                            }
                        }
                    }
                    
                    self.historicalData = HistoricalExchangeRate(disclaimer: disclaimer!, time: updated!, exchangeRate: datesToSafeArray)
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
            
            OperationQueue.main.addOperation {
                self.tableView.reloadData()
            }
        }
        task.resume()
    }
}
