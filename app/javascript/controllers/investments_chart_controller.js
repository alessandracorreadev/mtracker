import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  connect() {
    const canvas = this.element.querySelector("#investments-chart")
    if (!canvas) return

    const raw = this.element.dataset.chartData
    const data = raw ? JSON.parse(raw) : []

    if (data.length === 0) return

    const labels = data.map((d) => d.name)
    const values = data.map((d) => Number(d.total))
    const colorsRaw = this.element.dataset.chartColors
    const colors = colorsRaw ? JSON.parse(colorsRaw) : ["#05b355", "#0d1b2a"]


    this.chart = new Chart(canvas, {
      type: "doughnut",
      data: {
        labels,
        datasets: [
          {
            data: values,
            backgroundColor: labels.map((_, i) => colors[i % colors.length]),
            borderWidth: 2,
            borderColor: "rgba(255,255,255,0.1)",
            hoverOffset: 4
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        cutout: "75%",
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#212529",
            titleFont: { size: 14, weight: "bold" },
            bodyFont: { size: 13 },
            padding: 12,
            cornerRadius: 12,
            displayColors: true,
            borderColor: "rgba(255,255,255,0.1)",
            borderWidth: 1
          }
        },
      },
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
