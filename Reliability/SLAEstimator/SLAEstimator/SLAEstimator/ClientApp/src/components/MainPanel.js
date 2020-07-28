import React, { Component } from 'react';
import { Navigation } from './Navigation';
import { SearchBar } from './SearchBar';
import { Services } from './Services';
import { SLAestimation } from './SLAestimation';
import { ServiceAlert } from './ServiceAlert';

export class MainPanel extends Component {

    constructor(props) {
        super(props);

        const slaEstimation = JSON.parse(localStorage.getItem('slaEstimation')) || [];

        const tiers = JSON.parse(localStorage.getItem('tiers')) || this.getResetTiers();

        const slaTotal = this.calculateSla(slaEstimation);
        const slaTotalMultiRegion = this.calculateSlaMultiRegion(slaEstimation, tiers)
        const downTime = this.calculateDownTime(slaTotal)
        const downTimeMultiRegion = this.calculateDownTime(slaTotalMultiRegion)


        this.state = {
            serviceCategories: [], selectedServices: [], selectedCategory: "",
            tiers: tiers,
            slaEstimation: slaEstimation,
            slaTotal: slaTotal,
            slaTotalMultiRegion: slaTotalMultiRegion,
            downTime: downTime,
            downTimeMultiRegion: downTimeMultiRegion,
            addServiceClass: "addservice-alert-hide",
            currentTier: "Global",
            filter: false, loading: true
        };
        this.selectCategory = this.selectCategory.bind(this);
        this.selectService = this.selectService.bind(this);
        this.searchTextEnter = this.searchTextEnter.bind(this);
        this.clearSearch = this.clearSearch.bind(this);
        this.deleteEstimationCategory = this.deleteEstimationCategory.bind(this);
        this.expandCollapseEstimationCategory = this.expandCollapseEstimationCategory.bind(this);
        this.deleteEstimationTier = this.deleteEstimationTier.bind(this);
        this.expandCollapseEstimationTier = this.expandCollapseEstimationTier.bind(this);
        this.deleteAll = this.deleteAll.bind(this);
        this.expandAll = this.expandAll.bind(this);
        this.collapseAll = this.collapseAll.bind(this);
        this.setTier = this.setTier.bind(this);
        this.selectTierRegion = this.selectTierRegion.bind(this);
        this.calculateTierSla = this.calculateTierSla.bind(this);
    }

    getResetTiers() {
        return [
            { name: 'Global', pairedRegion: 'no' },
            { name: 'Web', pairedRegion: 'no' },
            { name: 'Api', pairedRegion: 'no' },
            { name: 'Data', pairedRegion: 'no' },
            { name: 'Security', pairedRegion: 'no' },
            { name: 'Network', pairedRegion: 'no' },

        ]
    }

    selectCategory(selectedCategory) {
        this.setState({
            selectedServices: selectedCategory.services,
            selectedCategory: selectedCategory.categoryName
        });
    }

    clearSearch(evt) {
        evt.currentTarget.parentElement.children[0].value = "";

        let displayServices = this.state.allservices.filter(o => o.categoryName === this.state.selectedCategory);

        this.setState({
            selectedServices: displayServices,
            filter: false
        });
    }

    searchTextEnter(textValue) {
        let displayServices = [];
        let filter = false;

        if (textValue.length > 0) {
            displayServices = this.state.allservices.filter(o => o.name.toLowerCase().includes(textValue.toLowerCase()));
            filter = true;
        }
        else {
            displayServices = this.state.allservices.filter(o => o.categoryName === this.state.selectedCategory);
        }

        this.setState({
            selectedServices: displayServices,
            filter: filter
        });
    }

    calculateTierSla(tier) {
        const slaEstimation = [...this.state.slaEstimation];

        return this.calculateSla(slaEstimation.filter(e => e.tier === tier));
    }

    calculateSlaMultiRegion(slaEstimation, tiers) {
        if (slaEstimation.length == 0)
            return 0;

        let total = 1;
        let services = slaEstimation.map(x => x.key);

        for (var i = 0; i < services.length; i++) {
            const tier = services[i].tier;
            const regionOption = tiers.find(t => t.name == tier).pairedRegion;
            const sla = services[i].service.sla/100;
            const value = regionOption === 'yes' ? 1-((1-sla) * (1-sla)) : sla;

            total = total * value;
        }

        return Math.round(((total * 100) + Number.EPSILON) * 1000) / 1000;
    }

    calculateSla(slaEstimation) {

        if (slaEstimation.length == 0)
            return 0;

        if (slaEstimation.length == 1)
            return slaEstimation[0].key.service.sla;

        let total = 1;
        let services = slaEstimation.map(x => x.key);

        for (var i = 0; i < services.length; i++) {
            total = total * services[i].service.sla / 100;
        }

        return Math.round(((total * 100) + Number.EPSILON) * 1000) / 1000;
    }

    calculateDownTime(sla) {
        if (sla == 0)
            return 0;

        return Math.round((44640 * (1 - (sla / 100)) + Number.EPSILON) * 100) / 100;
    }

    selectService(selectedService) {

        const service = this.state.selectedServices.find(o => o.name === selectedService);
        const slaEstimation = [...this.state.slaEstimation];

        const key = { id: this.state.slaEstimation.length, service: service, tier: this.state.currentTier}

        slaEstimation.push({ id: this.state.slaEstimation.length, key: key, tier: this.state.currentTier });

        const slaTotal = this.calculateSla(slaEstimation);
        const downTime = this.calculateDownTime(slaTotal)

        const slaTotalMultiRegion = this.calculateSlaMultiRegion(slaEstimation, this.state.tiers);
        const downTimeMultiRegion = this.calculateDownTime(slaTotalMultiRegion)

        this.setState({ addServiceClass: "addservice-alert-visible" });

        setTimeout(() => {
            this.setState({ addServiceClass: "addservice-alert-hide" });
        }, 1000);

        this.setState({
            selectedService: selectedService,
            slaEstimation: slaEstimation,
            slaTotal: slaTotal,
            downTime: downTime,
            slaTotalMultiRegion: slaTotalMultiRegion,
            downTimeMultiRegion: downTimeMultiRegion,
        });

        localStorage.setItem('slaEstimation', JSON.stringify(slaEstimation));
    }

    expandCollapseEstimationCategory(evt) {
        var updownimage = evt.currentTarget;
        var divPanel = evt.currentTarget.parentElement.parentElement.parentElement.children[2];
        divPanel.className = divPanel.className === "div-hide" ? "div-show" : "div-hide";
        updownimage.className = updownimage.className === "up-arrow" ? "down-arrow" : "up-arrow";
    }

    deleteEstimationCategory(evt) {
        const category = evt.currentTarget.parentElement.id;
        const tier = evt.currentTarget.parentElement.parentElement.id
        const slaEstimation = [...this.state.slaEstimation];

        const filteredEstimation = slaEstimation.filter(e => e.key.service.categoryName != category || e.tier != tier);

        const slaTotal = this.calculateSla(filteredEstimation);
        const downTime = this.calculateDownTime(slaTotal)

        this.setState({
            slaEstimation: filteredEstimation,
            slaTotal: slaTotal,
            downTime: downTime
        });

        localStorage.setItem('slaEstimation', JSON.stringify(filteredEstimation));
    }

    setTier(evt) {
        this.setState({
            currentTier: evt.target.options[evt.target.selectedIndex].label
        });
    }

    selectTierRegion(evt) {
        const regionOption = evt.target.options[evt.target.selectedIndex].value;
        const tier = evt.target.id;

        const tiers = [...this.state.tiers];
        var index = tiers.findIndex(t => t.name === tier);
        tiers[index].pairedRegion = regionOption;

        this.setState({
            tiers: tiers
        });

        const slaTotalMultiRegion = this.calculateSlaMultiRegion(this.state.slaEstimation, tiers)
        const downTimeMultiRegion = this.calculateDownTime(slaTotalMultiRegion)

        this.setState({
            slaTotalMultiRegion: slaTotalMultiRegion,
            downTimeMultiRegion: downTimeMultiRegion,
        });

        localStorage.setItem('tiers', JSON.stringify(tiers));
    }

    expandCollapseEstimationTier(evt) {
        var updownimage = evt.currentTarget;
        var divPanel = evt.currentTarget.parentElement
            .parentElement.parentElement.children[1];

        var totalsPanel = evt.currentTarget.parentElement
            .parentElement.parentElement.children[2];

        divPanel.className = divPanel.className === "tier-hide" ? "tier-show" : "tier-hide";
        totalsPanel.className = totalsPanel.className === "tier-hide" ? "tier-show" : "tier-hide";
        updownimage.className = updownimage.className === "up-arrow" ? "down-arrow" : "up-arrow";

    }

    deleteEstimationTier(evt) {
        const tier = evt.target.parentElement.id;
        const slaEstimation = [...this.state.slaEstimation];

        const filteredEstimation = slaEstimation.filter(e => e.tier != tier);

        const slaTotal = this.calculateSla(filteredEstimation);
        const downTime = this.calculateDownTime(slaTotal)

        const tiers = [...this.state.tiers];
        var index = tiers.findIndex(t => t.name === tier);
        tiers[index].pairedRegion = 'no';

        this.setState({
            tiers: tiers,
            slaEstimation: filteredEstimation,
            slaTotal: slaTotal,
            downTime: downTime
        });

        localStorage.setItem('slaEstimation', JSON.stringify(filteredEstimation));
    }

    deleteAll() {

        const tiers = this.getResetTiers();

        this.setState({
            slaEstimation: [],
            slaTotal: 0,
            downTime: 0,
            slaTotalMultiRegion: 0,
            downTimeMultiRegion: 0,
            tiers: tiers
        });

        localStorage.setItem('slaEstimation', JSON.stringify([]));
    }

    expandAll(evt) {
        var divPanel = evt.currentTarget.parentElement.parentElement.children[2];
        divPanel.className = "tiers-panel-show";
    }

    collapseAll(evt) {
        var divPanel = evt.currentTarget.parentElement.parentElement.children[2];
        divPanel.className = "tiers-panel-hide";
    }

    componentDidMount() {
        this.populateServiceCategoryData();
    }

    renderMainPanel() {
        return (
            <div className="main-panel">
                <div className="top-panel">
                    <div className="top-title">
                        <h1 className="top-title-inner">SLA Estimator</h1>
                        <p className="top-title-inner-sub">Estimate the overall service level agreement of your services</p>
                    </div>
                    <div className="legal-site-spacer"></div>
                    <a href="https://azure.microsoft.com/support/legal/sla/">Click here the to see the full SLA description hosted on the Legal site.</a>
                    <div className="search-container">
                        <SearchBar onTextSearchEnter={this.searchTextEnter} onClearSearch={this.clearSearch} />
                    </div>
                    <div>
                        <div className="tier-label">
                            Tier
                        </div>
                        <div className="tier-option-div">
                            <select className="tier-option" onChange={ev => this.setTier(ev)}>
                                <option value="1">Global</option>
                                <option value="2">Web</option>
                                <option value="3">Api</option>
                                <option value="4">Data</option>
                                <option value="5">Security</option>
                                <option value="6">Network</option>
                            </select>
                        </div>
                    </div>
                    <ServiceAlert id="serviceAlert" className={this.state.addServiceClass} />
                    <div className="layout-parent-div">
                        <div className={!this.state.filter ? "layout-div-left" : "div-hide"}>
                            <Navigation visible={!this.state.filter} dataSource={this.state.serviceCategories} selectedCategory={this.state.selectedCategory} onSelectCategory={this.selectCategory} />
                        </div>
                        <div className={this.state.filter ? "layout-div-center" : "layout-div-right"}>
                            <Services dataSource={this.state.selectedServices} onSelectService={this.selectService} />
                        </div>
                    </div>
                </div>
                <div className="sla-estimation-panel">
                    <SLAestimation slaEstimationData={this.state.slaEstimation} tier={this.state.currentTier}
                        tiers={this.state.tiers}
                        onDeleteEstimationCategory={this.deleteEstimationCategory}
                        onExpandCollapseEstimationCategory={this.expandCollapseEstimationCategory}
                        onExpandCollapseEstimationCategory={this.expandCollapseEstimationCategory}
                        onDeleteEstimationTier={this.deleteEstimationTier}
                        onExpandCollapseEstimationTier={this.expandCollapseEstimationTier}
                        onDeleteAll={this.deleteAll} onExpandAll={this.expandAll} onCollapseAll={this.collapseAll}
                        onSelectTierRegion={this.selectTierRegion}
                        calculateTierSla={this.calculateTierSla}
                        calculateDownTime={this.calculateDownTime}
                        slaTotal={this.state.slaTotal}
                        downTime={this.state.downTime}
                        slaTotalMultiRegion={this.state.slaTotalMultiRegion}
                        downTimeMultiRegion={this.state.downTimeMultiRegion}
                    />
                </div>
            </div>
        );
    }

    render() {
        let contents = this.renderMainPanel();

        return (
            <div>
                {contents}
            </div>
        );
    }

    async populateServiceCategoryData() {
        const response = await fetch('servicecategory');
        const data = await response.json();

        const allservices = data.map(x => x.services).reduce(
            (x, y) => x.concat(y));

        this.setState({ serviceCategories: data, allservices, selectedServices: data[0].services, selectedCategory: data[0].categoryName, loading: false });
    }
}
